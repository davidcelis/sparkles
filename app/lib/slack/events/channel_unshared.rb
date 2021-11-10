module Slack
  module Events
    class ChannelUnshared < Base
      def handle
        channel = ::Channel.find_by!(slack_team_id: slack_team_id, slack_id: payload[:channel])
        channel.update!(shared: payload[:is_ext_shared])

        # If the channel is no longer shared anywhere, re-join it.
        team.api_client.conversations_join(channel: channel.slack_id) unless channel.shared?
      end
    end
  end
end
