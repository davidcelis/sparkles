module Commands
  module Slack
    class Leaderboard < Base
      def execute
        matches = params[:text].match(Commands::Slack::LEADERBOARD)
        options = {
          slack_team_id: params[:team_id],
          slack_user_id: matches[:slack_user_id],
          response_url: params[:response_url]
        }

        LeaderboardWorker.perform_async(options)
      end
    end
  end
end
