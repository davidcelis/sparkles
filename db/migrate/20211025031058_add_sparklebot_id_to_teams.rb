class AddSparklebotIdToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :sparklebot_id, :string
  end
end
