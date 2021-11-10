class AddSharedAndReadOnlyToChannels < ActiveRecord::Migration[6.1]
  def change
    add_column :channels, :shared, :boolean, null: false, default: false
    add_column :channels, :read_only, :boolean, null: false, default: false
  end
end
