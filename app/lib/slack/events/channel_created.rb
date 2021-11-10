module Slack
  module Events
    class ChannelCreated < Base
      def handle
        response = team.api_client.conversations_info(channel: payload.dig(:channel, :id))
        slack_channel = Slack::Channel.from_api_response(response.channel, slack_team_id: team.slack_id)

        ::Channel.upsert(slack_channel.attributes, unique_by: [:slack_team_id, :slack_id])
        return if slack_channel.shared?

        # If it isn't shared, join the channel so that if it is eventually made
        # private, we won't lose access.
        team.api_client.conversations_join(channel: slack_channel.slack_id)
      end
    end
  end
end
