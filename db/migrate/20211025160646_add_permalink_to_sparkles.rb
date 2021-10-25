class AddPermalinkToSparkles < ActiveRecord::Migration[6.1]
  def change
    add_column :sparkles, :permalink, :string
  end
end
