module Slack
  module Events
    class ChannelUnshared
      def self.execute(slack_team_id:, payload:)
        channel = ::Channel.find_by!(slack_team_id: slack_team_id, slack_id: payload[:channel])
        channel.update!(shared: payload[:is_ext_shared])

        # This event is triggered when channel is unshared with one workspace;
        # if it's still shared with any other workspaces, we're done here.
        return if channel.shared?

        # If not, Sparklebot will re-join it.
        team = ::Team.find_by!(slack_id: slack_team_id)
        team.api_client.conversations_join(channel: channel.slack_id) unless channel.shared?
      end
    end
  end
end
