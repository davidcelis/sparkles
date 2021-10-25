module Slack
  module Events
    class URLVerification < Base
      def handle
        payload.slice(:challenge)
      end
    end
  end
end
