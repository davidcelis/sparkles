module Slack
  module Events
    class UserChange
      def self.execute(slack_team_id:, payload:)
        # I think we might get these events for users who are associated to a
        # team based on an enterprise grid, so we should just ignore them.
        return if payload.dig(:user, :team_id) != slack_team_id

        # Don't persist users who are bots or restricted guests.
        slack_user = ::Slack::User.from_api_response(payload[:user])
        return unless slack_user.human_teammate?

        ::User.upsert(slack_user.attributes, unique_by: [:slack_team_id, :slack_id])
      end
    end
  end
end
