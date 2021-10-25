module Slack
  module Events
    class ChannelUnarchive < Base
      def handle
        channel = ::Channel.find(payload[:channel])
        channel.update!(archived: false)

        {ok: true}
      end
    end
  end
end
