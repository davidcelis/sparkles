module Commands
  module Slack
    class Leaderboard < Base
      def execute
        matches = params[:text].match(Commands::Slack::LEADERBOARD)
        options = {
          team_id: params[:team_id],
          user_id: matches[:user_id],
          response_url: params[:response_url]
        }

        LeaderboardWorker.perform_async(options)
      end
    end
  end
end
