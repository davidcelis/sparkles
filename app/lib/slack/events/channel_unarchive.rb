module Slack
  module Events
    class ChannelUnarchive
      def self.execute(slack_team_id:, payload:)
        # If we already have the channel stored, we only need to update the
        # flag to reflect its been unarchived
        if (channel = ::Channel.find_by(slack_team_id: slack_team_id, slack_id: payload[:channel]))
          channel.update!(archived: false)
          return
        end

        # If we don't have it stored, it means we were installed after this
        # channel was created and archived and never fetched it in the first
        # place. We need to get the full object from the API to store it.
        team = ::Team.find_by!(slack_id: slack_team_id)
        response = team.api_client.conversations_info(channel: payload[:channel])
        slack_channel = Slack::Channel.from_api_response(response.channel, slack_team_id: team.slack_id)
        channel = ::Channel.create!(slack_channel.attributes)

        # Also join the channel so that if it is eventually made private,
        # we won't lose access.
        team.api_client.conversations_join(channel: channel.slack_id) unless channel.shared?
      end
    end
  end
end
