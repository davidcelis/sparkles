class SparkleJob < ApplicationJob
  queue_as :default

  WORDS_OF_ENCOURAGEMENT = [
    "Amazing",
    "Aw yiss",
    "Awesome",
    "Bam",
    "Beautiful",
    "Boo-yah",
    "Bravo",
    "Cheers",
    "Cool",
    "Excellent",
    "Exciting",
    "Fabulous",
    "Fantastic",
    "Good news, everyone",
    "Great",
    "Hell yeah",
    "Hooray",
    "Oh-ho",
    "Oh yeah",
    "Rad",
    "Rock and roll",
    "Shut the front door",
    "Sweet",
    "Tada",
    "Whee",
    "Woah",
    "Woo",
    "Woo-hoo",
    "Woot",
    "Wow",
    "Yay",
    "Yeah",
    "Yesss",
    "Yippee"
  ].freeze

  def perform(options)
    options = options.with_indifferent_access

    team = Team.find(options[:team_id])
    recipient = team.api_client.users_info(user: options[:recipient_id]).user

    if recipient.deleted
      text = "Oops, I can’t find that person anymore :sweat: They’ve either left the team or been deactivated. Sorry!"

      return team.api_client.chat_postMessage(channel: options[:channel_id], text: text)
    end

    if recipient.is_bot
      text = if recipient.id == team.sparklebot_id
        "Aww, thank you, <@#{options[:user_id]}>! That’s so thoughtful, but I’m already swimming in sparkles! I couldn’t possibly take one of yours, but I apprecate the gesture nonetheless :sparkles:"
      else
        "It’s so nice that you want to recognize one of my fellow bots! They’ve all politely declined to join the fun of hoarding sparkles, but I’ll pass along your thanks."
      end

      return team.api_client.chat_postMessage(channel: options[:channel_id], text: text)
    end

    # First things first: one reaction per message per user is enough!
    return if options[:reaction_to_ts] && team.sparkles.exists?(user_id: recipient.id, reaction_to_ts: options[:reaction_to_ts], from_user_id: options[:user_id])

    ActiveRecord::Base.transaction do
      # If this sparkle is in response to a reaction, will give the sparkle a
      # default reason that includes a link to the message that was reacted to.
      reaction_permalink = nil
      reason = if options[:reaction_to_ts]
        reaction_permalink = team.api_client.chat_getPermalink(channel: options[:channel_id], message_ts: options[:reaction_to_ts]).permalink
        reaction_permalink = URI(reaction_permalink)

        "because I approve <#{reaction_permalink}|this message>!"
      else
        options[:reason]
      end

      sparkle_count = team.sparkles.where(user_id: recipient.id).count
      sparkle = team.sparkles.new(
        user_id: recipient.id,
        from_user_id: options[:user_id],
        channel_id: options[:channel_id],
        reaction_to_ts: options[:reaction_to_ts],
        reason: reason
      )

      text = if sparkle_count == 0
        ":tada: <@#{recipient.id}> just got their first :sparkle:! :tada:"
      else
        prefix = WORDS_OF_ENCOURAGEMENT.sample + ("!" * rand(1..3))

        "#{prefix} <@#{recipient.id}> now has #{sparkle_count + 1} sparkles :sparkles:"
      end

      existing_reactions = team.sparkles.where(reaction_to_ts: options[:reaction_to_ts])
      if sparkle.user_id == sparkle.from_user_id || (sparkle.reaction? && existing_reactions.where("user_id = from_user_id").exists?)
        text += "\n\nNothing wrong with a little pat on the back, eh <@#{sparkle.user_id}>?"
      end

      # If the sparkle is being given via a reaction, we want to post our
      # response as a threaded reply to the original message. However, if that
      # message is itself in a thread, we need to get the parent message's ts
      # so we can reply to that instead. Thankfully, this will be in the URL
      # params of the permalink we got earlier.
      thread_ts = if sparkle.reaction?
        query = Rack::Utils.parse_query(reaction_permalink.query)
        query.fetch("thread_ts") { sparkle.reaction_to_ts }
      end

      # Now we'll post our response; however, if sparkles are being given via
      # multiple reactions, we want to update whatever message we've already
      # posted with the latest count.
      if sparkle.reaction? && (existing_reaction = existing_reactions.first)
        team.api_client.chat_update(channel: options[:channel_id], ts: existing_reaction.message_ts, text: text, as_user: true)
        sparkle.update!(message_ts: existing_reaction.message_ts, permalink: existing_reaction.permalink)
      else
        message = team.api_client.chat_postMessage(channel: options[:channel_id], text: text, thread_ts: thread_ts)
        permalink = team.api_client.chat_getPermalink(channel: options[:channel_id], message_ts: message.ts).permalink

        sparkle.update!(message_ts: message.ts, permalink: permalink)
      end
    end
  rescue Slack::Web::Api::Errors::UserNotFound
    text = "I couldn’t find the person you’re trying to sparkle :sweat: Make sure you’re using a highlighted @mention!"

    team.api_client.chat_postMessage(channel: options[:channel_id], text: text)
  rescue Slack::Web::Api::Error => e
    Sentry.capture_exception(e)

    text = "Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime."

    unless options[:reaction_to_ts]
      text += " Here’s that sparkle you tried to give away so you can try again more easily!\n\n/sparkle <@#{options[:recipient_id]}> #{options[:reason]}"
    end

    if (response_url = options[:response_url])
      Faraday.post(response_url, {text: text}.to_json, "Content-Type" => "application/json")
    else
      team.api_client.chat_postEphemeral(channel: options[:channel_id], user: options[:user_id], text: text)
    end
  ensure
    if options[:scheduled_message_id]
      team.api_client.chat_deleteScheduledMessage(channel: options[:channel_id], scheduled_message_id: options[:scheduled_message_id])
    end
  end
end
