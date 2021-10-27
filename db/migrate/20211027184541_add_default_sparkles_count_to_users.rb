class AddDefaultSparklesCountToUsers < ActiveRecord::Migration[6.1]
  def change
    User.where(sparkles_count: nil).update_all(sparkles_count: 0)

    change_column_default :users, :sparkles_count, from: nil, to: 0
    change_column_null :users, :sparkles_count, false
  end
end
