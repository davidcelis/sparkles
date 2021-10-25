module Slack
  module Events
    class TeamRename < Base
      def handle
        team.update!(name: payload[:name])
      end
    end
  end
end
