class AddDetailsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :name, :string
    add_column :users, :username, :string
    add_column :users, :image_url, :string
    add_column :users, :deactivated, :boolean, null: false, default: false
  end
end
