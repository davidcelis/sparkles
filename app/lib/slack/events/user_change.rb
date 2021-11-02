module Slack
  module Events
    class UserChange < Base
      def handle
        # I think we might get these events for users who are associated to a
        # team based on an enterprise grid, so we should just ignore them.
        return if payload.dig(:user, :team_id) != slack_team_id

        slack_user = ::Slack::User.from_api_response(payload[:user])
        return if slack_user.bot?

        ::User.upsert(slack_user.attributes, unique_by: [:slack_team_id, :slack_id])
      end
    end
  end
end
