class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams, id: :string do |t|
      t.string :name, null: false
      t.string :sparklebot_id, null: false
      t.boolean :active, null: false, default: true

      t.text :access_token, null: false

      t.timestamps
    end
  end
end
