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
    team = Team.find_by(slack_id: options[:slack_team_id])

    response = team.api_client.users_info(user: options[:slack_sparklee_id])
    slack_sparklee = Slack::User.from_api_response(response.user)

    if slack_sparklee.bot?
      text = if slack_sparklee.sparklebot?
        "Aww, thank you, <@#{options[:slack_sparkler_id]}>! That's so thoughtful, but I'm already swimming in sparkles! I couldn't possibly take one of yours, but I apprecate the gesture nonetheless :sparkles:"
      else
        "It's so nice that you want to recognize one of my fellow bots! They've all politely declined to join the fun of sparkle hoarding, but I'll pass along your thanks."
      end

      return team.api_client.chat_postMessage(channel: options[:slack_channel_id], text: text)
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

    # Create the channel
    sparkle = Sparkle.create!(
      slack_team_id: team.slack_id,
      slack_sparkler_id: sparkler.slack_id,
      slack_sparklee_id: sparklee.slack_id,
      slack_channel_id: options[:slack_channel_id],
      reason: options[:reason]
    )

    text = if sparklee.sparkles.count == 1
      ":tada: <@#{sparklee.slack_id}> just got their first :sparkle:! :tada:"
    else
      prefix = WORDS_OF_ENCOURAGEMENT.sample + ("!" * rand(1..3))
      "#{prefix} <@#{sparklee.slack_id}> now has #{sparklee.sparkles.count} sparkles :sparkles:"
    end

    if sparklee == sparkler
      text += "\n\nNothing wrong with a little pat on the back, eh <@#{sparkler.slack_id}>?"
    end

    message = team.api_client.chat_postMessage(channel: sparkle.slack_channel_id, text: text)

    # Get the ten most recent messages in the channel so we can find the
    # original message, grab its permalink, and assign it to the Sparkle
    response = team.api_client.conversations_history(channel: sparkle.slack_channel_id, limit: 10)
    message = response.messages.find { |m| m.user == sparkle.slack_sparkler_id && m.text.include?(sparkle.reason) }

    response = team.api_client.chat_getPermalink(channel: sparkle.slack_channel_id, message_ts: message.ts)
    sparkle.update!(permalink: response.permalink)
  end
end
