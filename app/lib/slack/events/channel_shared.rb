module Slack
  module Events
    class ChannelShared
      def self.execute(slack_team_id:, payload:)
        team = ::Team.find_by!(slack_id: slack_team_id)

        # This event can be received if an exist channel is shared _or_ a new
        # shared channel is created; an upsert will work for both cases.
        response = team.api_client.conversations_info(channel: payload[:channel])
        slack_channel = Slack::Channel.from_api_response(response.channel, slack_team_id: team.slack_id)

        # Just in case?
        attributes = slack_channel.attributes.merge(shared: true)
        ::Channel.upsert(attributes, unique_by: [:slack_team_id, :slack_id])
      end
    end
  end
end
