module Slack
  module SlashCommands
    class Sparkle < Base
      def execute
        unless ::Channel.exists?(slack_team_id: params[:team_id], slack_id: params[:channel_id])
          @result = {
            response_type: :ephemeral,
            text: "Oops, you need to `/invite` me to this channel before I can give out sparkles here!"
          }
          return
        end

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
