class AddSlackTokenToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :slack_token, :string
  end
end
