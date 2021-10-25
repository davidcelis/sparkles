module Slack
  module Events
    class ChannelArchive < Base
      def handle
        channel = ::Channel.find(payload[:channel])
        channel.update!(archived: true)
      end
    end
  end
end
