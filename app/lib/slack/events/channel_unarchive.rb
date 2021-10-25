module Slack
  module Events
    class ChannelUnarchive < Base
      def handle
        # If we already have the channel stored, we only need to update the
        # flag to reflect its been unarchived
        if (channel = ::Channel.find_by(id: payload[:channel])
          channel.update!(archived: false)

          return {ok: true}
        end

        # If we don't have it stored, it means we were installed after this
        # channel was created and archived and never fetched it in the first
        # place. We need to get the full object from the API to store it.
        response = team.api_client.conversations_info(channel: payload[:channel])
        slack_channel = Slack::Channel.from_api_response(response.channel)

        ::Channel.upsert(slack_channel.attributes)

        # Also join the channel so that if it is eventually made private,
        # we won't lose access.
        team.api_client.conversations_join(channel: slack_channel.id)

        {ok: true}
      end
    end
  end
end
