module Slack
  module SlashCommands
    class Sparkle
      FORMAT = /\A#{SlackHelper::USER_PATTERN}(\s+(?<reason>.+))?\z/

      def self.execute(params)
        matches = params[:text].match(FORMAT)
        options = {
          slack_team_id: params[:team_id],
          slack_channel_id: params[:channel_id],
          slack_sparkler_id: params[:user_id],
          slack_sparklee_id: matches[:slack_user_id],
          reason: matches[:reason]
        }

        SparkleWorker.perform_async(options)

        Result.new(response_type: :in_channel)
      end
    end
  end
end
