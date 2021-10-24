module Commands
  module Slack
    class SparkleUser
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

      def initialize(text)
        matches = text.match(Commands::Slack::SPARKLE_USER)

        @sparklee_id = matches[:user_id]
        @reason = matches[:reason]
      end

      def execute(params)
        team = Team.find(params[:team_id])

        user_info_response = team.api_client.users_info(user: @sparklee_id)
        if user_info_response.user.is_bot || user_info_response.user.id == "USLACKBOT"
          text = if user_info_response.user.real_name == "Sparklebot"
            "Aww, thank you, <@#{params[:user_id]}>! That's so thoughtful, but I'm already swimming in sparkles! I couldn't possibly take one of yours, but I apprecate the gesture nonetheless :sparkles:"
          else
            "It's so nice that you want to recognize one of my fellow bots! They've all politely declined to join the fun of sparkle hoarding, but I'll pass along your thanks."
          end

          return Commands::Slack::Result.new(text: text)
        end

        sparkler = team.users.find_or_create_by(id: params[:user_id])
        sparklee = team.users.find_or_create_by(id: @sparklee_id)
        sparkle = sparklee.sparkles.create!(
          sparkler_id: sparkler.id,
          channel_id: params[:channel_id],
          reason: @reason
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

        Commands::Slack::Result.new(
          text: text,
          response_type: :in_channel
        )
      end
    end
  end
end
