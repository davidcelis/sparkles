module Slack
  module Events
    class TeamRename < Base
      def handle
        team.update!(name: payload[:name])

        {ok: true}
      end
    end
  end
end
