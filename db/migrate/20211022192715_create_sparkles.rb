class CreateSparkles < ActiveRecord::Migration[6.1]
  def change
    create_table :sparkles do |t|
      t.references :sparklee, type: :string, null: false
      t.references :sparkler, type: :string, null: false
      t.string :channel_id, null: :false
      t.string :reason

      t.timestamps
    end
  end
end
