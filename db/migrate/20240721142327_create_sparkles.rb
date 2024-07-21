class CreateSparkles < ActiveRecord::Migration[7.1]
  def change
    create_table :sparkles, id: :uuid do |t|
      t.references :user, null: false, type: :string
      t.references :from_user, null: false, type: :string
      t.text :reason

      t.references :team, null: false, foreign_key: true, type: :string
      t.references :channel, null: false, type: :string
      t.string :message_ts, null: false
      t.string :permalink, null: false

      t.timestamps
    end
  end
end
