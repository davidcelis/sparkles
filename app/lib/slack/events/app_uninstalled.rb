module Slack
  module Events
    class AppUninstalled
      def self.execute(slack_team_id:, payload:)
        team = ::Team.find_by!(slack_id: slack_team_id)
        team.update!(uninstalled: true)
      end
    end
  end
end
