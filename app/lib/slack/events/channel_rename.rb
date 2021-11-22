module Slack
  module Events
    class ChannelRename
      def self.execute(slack_team_id:, payload:)
        channel = ::Channel.find_by!(slack_team_id: slack_team_id, slack_id: payload.dig(:channel, :id))
        channel.update!(name: payload.dig(:channel, :name))
      end
    end
  end
end
