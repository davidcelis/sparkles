module Slack
  module Events
    class ChannelDeleted
      def self.execute(slack_team_id:, payload:)
        channel = ::Channel.find_by!(slack_team_id: slack_team_id, slack_id: payload[:channel])
        channel.update!(deleted: true)
      end
    end
  end
end
