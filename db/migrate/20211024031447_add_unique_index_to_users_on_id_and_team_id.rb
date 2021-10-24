class AddUniqueIndexToUsersOnIdAndTeamId < ActiveRecord::Migration[6.1]
  def change
    add_index :users, [:id, :team_id], unique: true
  end
end
