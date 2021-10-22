class CreateSparkles < ActiveRecord::Migration[6.1]
  def change
    create_table :sparkles do |t|
      t.references :sparklee, type: :string, null: false, foreign_key: {to_table: :users}
      t.references :sparkler, type: :string, null: false, foreign_key: {to_table: :users}
      t.string :channel_id, null: :false
      t.string :reason

      t.timestamps
    end
  end
end
