class CreateInitialSchema < ActiveRecord::Migration[6.1]
  def change
    create_table :teams do |t|
      t.string :slack_id, null: false
      t.string :name, null: false
      t.string :slack_token, null: false
      t.string :sparklebot_id, null: false
      t.string :icon_url

      t.timestamps null: false, default: -> { "now()" }

      t.index :slack_id, unique: true
    end

    create_table :users do |t|
      t.string :slack_team_id, null: false
      t.string :slack_id, null: false
      t.string :name, null: false
      t.string :username
      t.string :image_url
      t.boolean :deactivated, null: false, default: false
      t.integer :sparkles_count, null: false, default: 0

      t.timestamps null: false, default: -> { "now()" }

      t.index [:slack_team_id, :slack_id], unique: true
    end

    create_table :channels do |t|
      t.string :slack_team_id, null: false
      t.string :slack_id, null: false
      t.string :name, null: false

      t.boolean :private, null: false, default: false
      t.boolean :archived, null: false, default: false
      t.boolean :deleted, null: false, default: false

      t.timestamps null: false, default: -> { "now()" }

      t.index [:slack_team_id, :slack_id], unique: true
    end

    create_table :sparkles do |t|
      t.string :slack_team_id, null: false
      t.string :slack_sparklee_id, null: false
      t.string :slack_sparkler_id, null: false
      t.string :slack_channel_id, null: false
      t.string :reason
      t.string :permalink

      t.timestamps null: false, default: -> { "now()" }

      t.index [:slack_team_id, :slack_sparklee_id]
      t.index [:slack_team_id, :slack_sparkler_id]
    end
  end
end
