module Slack
  module Events
    class ChannelDeleted < Base
      def handle
        channel = ::Channel.find_by!(slack_team_id: slack_team_id, slack_id: payload[:channel_id])
        channel.update!(deleted: true)
      end
    end
  end
end
