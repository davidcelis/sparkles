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

    response = team.api_client.users_info(user: options[:slack_sparklee_id])
    slack_sparklee = Slack::User.from_api_response(response.user)

    if slack_sparklee.bot?
      text = if slack_sparklee.sparklebot?
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

    # Get the ten most recent messages in the channel so we can find the
    # original message, grab its permalink, and assign it to the Sparkle
    history = team.api_client.conversations_history(channel: channel.slack_id, limit: 10)
    message = history.messages.find { |m| m.user == sparkler.slack_id && m.text.include?(options[:reason]) }
    message = team.api_client.chat_getPermalink(channel: channel.slack_id, message_ts: message.ts)

    # Create the sparkle
    sparklee.sparkles.create!(team: team, sparkler: sparkler, channel: channel, reason: options[:reason], permalink: message.permalink)

    text = if sparklee.sparkles.count == 1
      ":tada: <@#{sparklee.slack_id}> just got their first :sparkle:! :tada:"
    else
      prefix = WORDS_OF_ENCOURAGEMENT.sample + ("!" * rand(1..3))
      "#{prefix} <@#{sparklee.slack_id}> now has #{sparklee.sparkles.count} sparkles :sparkles:"
    end

    if sparklee == sparkler
      text += "\n\nNothing wrong with a little pat on the back, eh <@#{sparkler.slack_id}>?"
    end

    if team.feed_channel_id
      team.api_client.chat_postMessage(
        channel: team.feed_channel_id,
        text: "<@#{options[:slack_sparkler_id]}> gave <@#{options[:slack_sparklee_id]}> a sparkle for <#{message.permalink}|#{options[:reason]}>"
      )
    end

    team.api_client.chat_postMessage(channel: channel.slack_id, text: text)
  end
end
