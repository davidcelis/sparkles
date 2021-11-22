module Slack
  module Events
    class TeamRename
      def self.execute(slack_team_id:, payload:)
        team = ::Team.find_by!(slack_id: slack_team_id)
        team.update!(name: payload[:name])
      end
    end
  end
end
