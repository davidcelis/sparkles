module Slack
  module Events
    class UserChange < Base
      def handle
        slack_user = ::Slack::User.from_api_response(payload[:user])

        ::User.upsert(slack_user.attributes)
      end
    end
  end
end
