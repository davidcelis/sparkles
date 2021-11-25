class AddUninstalledFlagToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :uninstalled, :boolean, null: false, default: false

    add_index :teams, :uninstalled
  end
end
