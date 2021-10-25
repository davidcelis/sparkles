class AddSparklesCountToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :sparkles_count, :integer
  end
end
