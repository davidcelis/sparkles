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
    team = Team.find(options[:team_id])

    response = team.api_client.users_info(user: options[:sparklee_id])
    slack_sparklee = Slack::User.from_api_response(response.user)

    if slack_sparklee.bot?
      text = if slack_sparklee.sparklebot?
        "Aww, thank you, <@#{options[:sparkler_id]}>! That's so thoughtful, but I'm already swimming in sparkles! I couldn't possibly take one of yours, but I apprecate the gesture nonetheless :sparkles:"
      else
        "It's so nice that you want to recognize one of my fellow bots! They've all politely declined to join the fun of sparkle hoarding, but I'll pass along your thanks."
      end

      http.post(options[:response_url], {text: text, response_type: :in_channel})

      return
    end

    # Find the sparkler, adding them to our database if we haven't yet
    sparkler = team.users.find_or_initialize_by(id: options[:sparkler_id])
    if sparkler.new_record?
      response = team.api_client.users_info(user: sparkler.id)
      slack_sparkler = Slack::User.from_api_response(response.user)

      sparkler.update_attributes!(slack_sparkler.attributes)
    end

    # Find the sparklee, adding them to our database if we haven't yet
    sparklee = team.users.find_or_initialize_by(id: options[:sparklee_id])
    sparklee.update_attributes!(slack_sparklee.attributes) if sparklee.new_record?

    # Create the channel
    sparkle = Sparkle.create!(
      sparkler_id: sparkler.id,
      sparklee_id: sparklee.id,
      channel_id: options[:channel_id],
      reason: options[:reason]
    )

    text = if sparklee.sparkles.count == 1
      ":tada: <@#{sparklee.id}> just got their first :sparkle:! :tada:"
    else
      prefix = WORDS_OF_ENCOURAGEMENT.sample + ("!" * rand(1..3))
      "#{prefix} <@#{sparklee.id}> now has #{sparklee.sparkles.count} sparkles :sparkles:"
    end

    if sparklee == sparkler
      text += "\n\nNothing wrong with a little pat on the back, eh <@#{sparkler.id}>?"
    end

    http.post(options[:response_url], {text: text, response_type: :in_channel})
  end

  def http
    @http ||= Faraday.new do |f|
      f.request :json # Encode request bodies as JSON
      f.request :retry # Retry transient failures
    end
  end
end
