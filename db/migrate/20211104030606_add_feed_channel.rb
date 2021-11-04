class AddFeedChannel < ActiveRecord::Migration[6.1]
  def up
    add_column :teams, :feed_channel_id, :string
  end

  def down
    remove_column :teams, :feed_channel_id, :string
  end
end
