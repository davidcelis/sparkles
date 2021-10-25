module Commands
  module Slack
    class Sparkle < Base
      def execute
        unless Channel.exists?(id: params[:channel_id])
          text = "Oops, you need to `/invite` me to this channel before I can give out sparkles here!"

          return {response_type: :ephemeral, text: text}
        end

        matches = params[:text].match(Commands::Slack::SPARKLE_USER)
        options = {
          team_id: params[:team_id],
          channel_id: params[:channel_id],
          sparkler_id: params[:user_id],
          sparklee_id: matches[:user_id],
          reason: matches[:reason]
        }

        SparkleWorker.perform_async(options)

        @result = {response_type: :in_channel}
      end
    end
  end
end
