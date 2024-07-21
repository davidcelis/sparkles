module Slack
  module Events
    class AppUninstalled
      def self.process(team_id:, payload:)
        team = Team.find(team_id)

        team.update!(active: false)
      end
    end
  end
end
