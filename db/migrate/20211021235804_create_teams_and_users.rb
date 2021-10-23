class CreateTeamsAndUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :teams, id: :string do |t|
      t.string :slack_token, null: false

      t.timestamps
    end

    create_table :users, id: :string do |t|
      t.references :team, type: :string, null: false, foreign_key: true

      t.timestamps
    end
  end
end
