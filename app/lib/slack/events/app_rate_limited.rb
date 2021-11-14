module Slack
  module Events
    # We receive this event when our app has received too many events. There's
    # not really anything we can do in response, so we don't. We'll update our
    # local cache with anything we missed with the next run of our daily worker
    class AppRateLimited < Base
      def handle
      end
    end
  end
end
