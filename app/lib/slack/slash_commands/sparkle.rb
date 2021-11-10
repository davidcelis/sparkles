module Slack
  module SlashCommands
    class Sparkle < Base
      def execute
        matches = params[:text].match(Slack::SlashCommands::SPARKLE_USER)
        options = {
          slack_team_id: params[:team_id],
          slack_channel_id: params[:channel_id],
          slack_sparkler_id: params[:user_id],
          slack_sparklee_id: matches[:slack_user_id],
          reason: matches[:reason]
        }

        SparkleWorker.perform_async(options)

        @result = {response_type: :in_channel}
      end
    end
  end
end
