module Slack
  module Events
    class AppRateLimited < Base
      def handle
        {ok: true}
      end
    end
  end
end
