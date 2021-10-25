module Slack
  module Events
    class MemberJoinedChannel < Base
      def handle
        return {ok: true} unless payload[:user] == team.sparklebot_id

        response = team.api_client.conversations_info(channel: payload[:channel])
        slack_channel = Slack::Channel.from_api_response(response.channel)

        # Sparklebot automatically joins public channels, so ignore this unless
        # it's a private channel
        return {ok: true} unless slack_channel.private?

        ::Channel.upsert(slack_channel.attributes)

        {ok: true}
      end
    end
  end
end
