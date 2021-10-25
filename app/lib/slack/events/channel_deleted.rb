module Slack
  module Events
    class ChannelDeleted < Base
      def handle
        ::Channel.find(payload[:channel]).update!(deleted: true)
      end
    end
  end
end
