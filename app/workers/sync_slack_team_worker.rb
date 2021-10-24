class SyncSlackTeamWorker < ApplicationWorker
  def perform(id)
    team = Team.find(id)

    # Sync team info
    slack_team = Slack::Team.from_api_response(team.api_client.team_info.team)
    team.update!(slack_team.attributes)

    # Sync users
    users = []
    team.api_client.users_list(sleep_interval: 5, max_retries: 20) do |users_response|
      users += users_response.members.map { |m| Slack::User.from_api_response(m) }
    end
    users = users.reject(&:bot?).map(&:attributes)
    User.upsert_all(users, unique_by: [:id, :team_id])

    # Sync channels
    channels = []
    team.api_client.conversations_list(types: "public_channel,private_channel", sleep_interval: 5, max_retries: 20) do |conversations_response|
      channels += conversations_response.channels.map do |channel|
        Slack::Channel.from_api_response(channel).tap { |c| c.team_id = team.id }
      end
    end
    channels = channels.reject(&:shared?).map(&:attributes)
    Channel.upsert_all(channels, unique_by: [:id, :team_id])
  end
end
