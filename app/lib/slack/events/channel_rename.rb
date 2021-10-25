module Slack
  module Events
    class ChannelRename < Base
      def handle
        channel = ::Channel.find(payload.dig(:channel, :id))
        channel.update!(name: payload.dig(:channel, :name))

        {ok: true}
      end
    end
  end
end
