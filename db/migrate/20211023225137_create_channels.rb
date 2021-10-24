class CreateChannels < ActiveRecord::Migration[6.1]
  def change
    create_table :channels, id: :string do |t|
      t.references :team, type: :string, null: false, foreign_key: true

      t.string :name, null: false
      t.boolean :private, null: false, default: false
      t.boolean :archived, null: false, default: false
      t.boolean :deleted, null: false, default: false

      t.index [:id, :team_id], unique: true

      t.timestamps
    end

    reversible do |dir|
      dir.up { change_column :sparkles, :channel_id, :string, null: false }
      dir.down { change_column :sparkles, :channel_id, :string, null: true }
    end

    add_foreign_key :sparkles, :channels
  end
end
