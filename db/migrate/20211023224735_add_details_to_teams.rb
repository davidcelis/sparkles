class AddDetailsToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :name, :string
    add_column :teams, :icon_url, :string
  end
end
