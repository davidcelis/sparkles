module Slack
  module Events
    class URLVerification < Base
      def handle
        @result = payload.slice(:challenge)
      end
    end
  end
end
