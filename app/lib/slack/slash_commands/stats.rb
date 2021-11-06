module Slack
  module SlashCommands
    class Stats < Base
      def execute
        matches = params[:text].match(Slack::SlashCommands::STATS)
        options = {
          slack_team_id: params[:team_id],
          slack_user_id: matches[:slack_user_id],
          slack_caller_id: params[:user_id],
          response_url: params[:response_url]
        }

        StatsWorker.perform_async(options)
      end
    end
  end
end
