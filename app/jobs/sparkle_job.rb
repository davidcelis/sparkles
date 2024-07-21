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

    ActiveRecord::Base.transaction do
      sparkle_count = team.sparkles.where(user_id: recipient.id).count
      sparkle = team.sparkles.new(
        user_id: recipient.id,
        from_user_id: options[:user_id],
        channel_id: options[:channel_id],
        reason: options[:reason]
      )

      text = if sparkle_count == 0
        ":tada: <@#{recipient.id}> just got their first :sparkle:! :tada:"
      else
        prefix = WORDS_OF_ENCOURAGEMENT.sample + ("!" * rand(1..3))

        "#{prefix} <@#{recipient.id}> now has #{sparkle_count + 1} sparkles :sparkles:"
      end

      if sparkle.user_id == sparkle.from_user_id
        text += "\n\nNothing wrong with a little pat on the back, eh <@#{sparkle.user_id}>?"
      end

      message = team.api_client.chat_postMessage(channel: options[:channel_id], text: text)
      permalink = team.api_client.chat_getPermalink(channel: options[:channel_id], message_ts: message.ts).permalink

      sparkle.update!(message_ts: message.ts, permalink: permalink)
    end
  rescue Slack::Web::Api::Errors::UserNotFound
    text = "I couldn’t find the person you’re trying to sparkle :sweat: Make sure you’re using a highlighted @mention!"

    team.api_client.chat_postMessage(channel: options[:channel_id], text: text)
  rescue Slack::Web::Api::Error => e
    Sentry.capture_exception(e)

    text = <<~TEXT.strip
      Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime. Here’s that sparkle you tried to give away so you can try again more easily!

      /sparkle <@#{options[:recipient_id]}> #{options[:reason]}
    TEXT

    Faraday.post(options[:response_url], {text: text}.to_json, "Content-Type" => "application/json")
  ensure
    team.api_client.chat_deleteScheduledMessage(channel: options[:channel_id], scheduled_message_id: options[:scheduled_message_id])
  end
end
