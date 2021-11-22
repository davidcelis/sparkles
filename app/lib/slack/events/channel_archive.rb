module Slack
  module Events
    class ChannelArchive
      def self.execute(slack_team_id:, payload:)
        channel = ::Channel.find_by!(slack_team_id: slack_team_id, slack_id: payload[:channel])
        channel.update!(archived: true)
      end
    end
  end
end
