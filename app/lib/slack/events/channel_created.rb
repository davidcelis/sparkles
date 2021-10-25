module Slack
  module Events
    class ChannelCreated < Base
      def handle
        response = team.api_client.conversations_info(channel: payload.dig(:channel, :id))
        slack_channel = Slack::Channel.from_api_response(response.channel)

        ::Channel.upsert(slack_channel.attributes)
      end
    end
  end
end
