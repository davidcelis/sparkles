class SparkleWorker < ApplicationWorker
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
    team = Team.find_by!(slack_id: options[:slack_team_id])
    channel = team.channels.find_by!(slack_id: options[:slack_channel_id])

    begin
      response = team.api_client.users_info(user: options[:slack_sparklee_id])
      slack_sparklee = Slack::User.from_api_response(response.user)

      if slack_sparklee.bot?
        text = if slack_sparklee.slack_id == team.sparklebot_id
          "Aww, thank you, <@#{options[:slack_sparkler_id]}>! That's so thoughtful, but I'm already swimming in sparkles! I couldn't possibly take one of yours, but I apprecate the gesture nonetheless :sparkles:"
        else
          "It's so nice that you want to recognize one of my fellow bots! They've all politely declined to join the fun of sparkle hoarding, but I'll pass along your thanks."
        end

        return team.api_client.chat_postMessage(channel: channel.slack_id, text: text)
      end

      if slack_sparklee.restricted?
        text = "Oops, I don't work with guest users or in shared channels right now :sweat: Sorry about that!"

        return team.api_client.chat_postMessage(channel: channel.slack_id, text: text)
      end

      # Find the sparkler, adding them to our database if we haven't yet
      sparkler = team.users.find_or_initialize_by(slack_id: options[:slack_sparkler_id])
      if sparkler.new_record?
        response = team.api_client.users_info(user: sparkler.slack_id)
        slack_sparkler = Slack::User.from_api_response(response.user)

        sparkler.update!(slack_sparkler.attributes)
      end

      # Find the sparklee, adding them to our database if we haven't yet
      sparklee = team.users.find_or_initialize_by(slack_id: options[:slack_sparklee_id])
      sparklee.update!(slack_sparklee.attributes) if sparklee.new_record?

      # Determine whether or not we should be showing leaderboard text in our response
      leaderboard_enabled = team.leaderboard_enabled? && sparklee.leaderboard_enabled?

      # Get the ten most recent messages in the channel so we can find the
      # original message, grab its permalink, and assign it to the Sparkle
      history = team.api_client.conversations_history(channel: channel.slack_id, limit: 10)
      search_text = options[:reason] || "/sparkle <@#{sparklee.slack_id}"
      message = history.messages.find { |m| m.user == sparkler.slack_id && m.text.include?(search_text) }
      message = team.api_client.chat_getPermalink(channel: channel.slack_id, message_ts: message.ts)

      # Create the sparkle
      sparklee.sparkles.create!(
        sparkler: sparkler,
        channel: channel,
        reason: options[:reason],
        permalink: message.permalink
      )

      prefix = WORDS_OF_ENCOURAGEMENT.sample + ("!" * rand(1..3))
      text = if !leaderboard_enabled
        "#{prefix} <@#{sparklee.slack_id}> just got a :sparkle:!"
      elsif sparklee.sparkles.count == 1
        ":tada: <@#{sparklee.slack_id}> just got their first :sparkle:! :tada:"
      else
        "#{prefix} <@#{sparklee.slack_id}> now has #{sparklee.sparkles.count} sparkles :sparkles:"
      end

      if sparklee == sparkler
        text += "\n\nNothing wrong with a little pat on the back, eh <@#{sparkler.slack_id}>?"
      end

      team.api_client.chat_postMessage(channel: channel.slack_id, text: text)

      if team.slack_feed_channel_id && !channel.private?
        team.api_client.chat_postMessage(
          channel: team.slack_feed_channel_id,
          text: ":sparkle: Somebody just got a <#{message.permalink}|sparkle>!"
        )
      end
    rescue Slack::Web::Api::Errors::UserNotFound
      text = "I couldn't find the teammate you're trying to sparkle :sweat: Make sure you're using a highlighted @mention and that they aren't a guest member!"
      team.api_client.chat_postMessage(channel: channel.slack_id, text: text)
    rescue
      # Just re-raise the error if this job has already been retried.
      raise if options[:retried]

      # If not, post an error message to the channel saying we _will_ retry.
      text = "Oops, I ran into a problem in the Sparkle pipeline :sweat: I'll notify my mechanic about this and keep trying for a bit in the meantime. Sorry!"
      team.api_client.chat_postMessage(channel: channel.slack_id, text: text)

      self.class.perform_async(options.merge(retried: true))
    end
  end
end
