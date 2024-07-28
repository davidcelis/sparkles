class AddReactionToTsToSparkles < ActiveRecord::Migration[7.1]
  def change
    add_column :sparkles, :reaction_to_ts, :string

    add_index :sparkles, [:team_id, :reaction_to_ts]

    # Ensures that a user can only give one sparkle reaction per message
    add_index :sparkles, [:team_id, :reaction_to_ts, :from_user_id], unique: true
  end
end
