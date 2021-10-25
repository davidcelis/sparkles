module Slack
  module Events
    class ChannelCreated < Base
      def handle
        response = team.api_client.conversations_info(channel: payload.dig(:channel, :id))
        slack_channel = Slack::Channel.from_api_response(response.channel)

        ::Channel.upsert(slack_channel.attributes)

        # Also join the channel so that if it is eventually made private,
        # we won't lose access.
        team.api_client.conversations_join(channel: slack_channel.id)
      end
    end
  end
end
