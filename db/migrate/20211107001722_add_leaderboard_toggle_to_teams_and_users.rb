class AddLeaderboardToggleToTeamsAndUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :leaderboard_enabled, :boolean, null: false, default: true
    add_column :users, :leaderboard_enabled, :boolean, null: false, default: true
  end
end
