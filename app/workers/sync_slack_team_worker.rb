class SyncSlackTeamWorker < ApplicationWorker
  def perform(id, first_sync = false)
    team = Team.find(id)

    # Sync team info
    slack_team = Slack::Team.from_api_response(team.api_client.team_info.team)
    team.update!(slack_team.attributes)

    # Sync users who aren't bots and aren't restricted
    users = []
    team.api_client.users_list(sleep_interval: 5, max_retries: 20) do |users_response|
      users += users_response.members.map { |m| Slack::User.from_api_response(m) }
    end
    users = users.select(&:human_teammate?)
    User.upsert_all(users.map(&:attributes), unique_by: [:slack_team_id, :slack_id])

    # Sync channels. If this is the first sync, we'll ignore archived channels
    # because people can't get sparkled in them anyway. If they're unarchived
    # at any point, we'll receive a `channel_unarchive` event and update our
    # local cache with its info.
    channels = []
    team.api_client.conversations_list(
      types: "public_channel,private_channel",
      exclude_archived: true,
      sleep_interval: 5,
      max_retries: 20
    ) do |conversations_response|
      channels += conversations_response.channels.map do |channel|
        Slack::Channel.from_api_response(channel, slack_team_id: team.slack_id)
      end
    end
    Channel.upsert_all(channels.map(&:attributes), unique_by: [:slack_team_id, :slack_id])

    # If this is the first sync when the app is installed, we'll join all public
    # channels. Being present in channels means we won't lose track of where
    # sparkles have come from; otherwise, if a public channel is made private,
    # we won't know about it and will suddenly fail to be able to query for
    # channels we stored locally but no longer have access to.
    return unless first_sync

    channels.select(&:sparklebot_should_join?).each do |channel|
      team.api_client.conversations_join(channel: channel.slack_id)
    end
  end
end
