class AddTeamAdminToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :team_admin, :boolean, null: false, default: false
  end
end
