class SyncSlackTeamWorker < ApplicationWorker
  def perform(id)
    team = Team.find(id)

    # Sync team info
    team_response = team.api_client.team_info
    team.update!(name: team_response.team.name, icon_url: team_response.team.icon.image_original)

    # Sync users
    users = []
    team.api_client.users_list(sleep_interval: 5, max_retries: 20) do |users_response|
      users += users_response.members.map do |member|
        {
          id: member.id,
          team_id: member.team_id,
          name: member.profile.real_name,
          username: member.profile.display_name,
          image_url: member.profile.image_url_512,
          deactivated: member.deleted,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end
    User.upsert_all(users, unique_by: [:id, :team_id])

    # Sync channels
    channels = []
    team.api_client.conversations_list(types: "public_channel,private_channel", sleep_interval: 5, max_retries: 20) do |conversations_response|
      channels += conversations_response.channels.map do |channel|
        {
          id: channel.id,
          team_id: team.id,
          name: channel.name,
          private: channel.is_private,
          archived: channel.is_archived,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end
    Channel.upsert_all(channels, unique_by: [:id, :team_id])
  end
end
