class DropOldForeignKeysFromSparkles < ActiveRecord::Migration[6.1]
  def up
    remove_column :sparkles, :slack_team_id
    remove_column :sparkles, :slack_sparklee_id
    remove_column :sparkles, :slack_sparkler_id
    remove_column :sparkles, :slack_channel_id
  end

  def down
    add_column :sparkles, :slack_team_id, :string
    add_column :sparkles, :slack_sparklee_id, :string
    add_column :sparkles, :slack_sparkler_id, :string
    add_column :sparkles, :slack_channel_id, :string

    add_index :sparkles, [:slack_team_id, :slack_sparklee_id]
    add_index :sparkles, [:slack_team_id, :slack_sparkler_id]

    execute <<~SQL
      UPDATE sparkles
      SET slack_sparklee_id = users.slack_id
      FROM users
      WHERE users.id = sparkles.sparklee_id;

      UPDATE sparkles
      SET slack_sparkler_id = users.slack_id
      FROM users
      WHERE users.id = sparkles.sparkler_id;

      UPDATE sparkles
      SET slack_channel_id = channels.slack_id
      FROM channels
      WHERE channels.id = sparkles.channel_id;

      UPDATE sparkles
      SET slack_team_id = users.slack_team_id
      FROM users
      WHERE users.slack_id = sparkles.slack_sparklee_id;
    SQL

    change_column_null :sparkles, :slack_team_id, false
    change_column_null :sparkles, :slack_sparklee_id, false
    change_column_null :sparkles, :slack_sparkler_id, false
    change_column_null :sparkles, :slack_channel_id, false
  end
end
