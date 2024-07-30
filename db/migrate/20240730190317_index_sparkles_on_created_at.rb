class IndexSparklesOnCreatedAt < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :sparkles, :created_at, algorithm: :concurrently, order: {created_at: :desc}
  end
end
