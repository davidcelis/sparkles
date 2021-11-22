module Slack
  module Events
    # We receive this event when our app has received too many events. There's
    # not really anything we can do in response, so we don't.
    class AppRateLimited
      def self.execute(slack_team_id:, payload:)
      end
    end
  end
end
