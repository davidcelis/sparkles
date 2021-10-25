module Slack
  module Events
    class ChannelDeleted < Base
      def handle
        ::Channel.find(payload[:id]).update!(deleted: true)

        {ok: true}
      end
    end
  end
end
