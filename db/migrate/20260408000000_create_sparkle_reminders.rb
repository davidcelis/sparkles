class CreateSparkleReminders < ActiveRecord::Migration[7.1]
  def change
    create_table :sparkle_reminders, id: :uuid do |t|
      t.string :user_id, null: false
      t.references :team, type: :string, null: false, foreign_key: true
      t.integer :day_of_week, null: false # 0=Sunday, 1=Monday, ..., 6=Saturday
      t.string :time_of_day, null: false  # "HH:MM" in 24h format
      t.string :timezone, null: false, default: "America/New_York"
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :sparkle_reminders, [:team_id, :user_id]
    add_index :sparkle_reminders, [:day_of_week, :active]
  end
end
