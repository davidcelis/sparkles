module Slack
  module Events
    class ReactionAdded
      def self.process(team_id:, payload:)
        # TODO: handle reaction_added events with the :sparkles: emoji
      end
    end
  end
end
