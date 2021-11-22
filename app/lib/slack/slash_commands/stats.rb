module Slack
  module SlashCommands
    class Stats
      FORMAT = /\Astats(\s+#{SlackHelper::USER_PATTERN})?\z/

      def self.execute(params)
        matches = params[:text].match(FORMAT)
        options = {
          slack_team_id: params[:team_id],
          slack_user_id: matches[:slack_user_id],
          slack_caller_id: params[:user_id],
          response_url: params[:response_url]
        }

        StatsWorker.perform_async(options)

        Result.new(response_type: :ephemeral)
      end
    end
  end
end
