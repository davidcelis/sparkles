class AddNewForeignKeysToSparkles < ActiveRecord::Migration[6.1]
  def change
    add_column :sparkles, :sparklee_id, :bigint
    add_index :sparkles, :sparklee_id

    add_column :sparkles, :sparkler_id, :bigint
    add_index :sparkles, :sparkler_id

    add_column :sparkles, :channel_id, :bigint
    add_index :sparkles, :channel_id

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE sparkles
          SET sparklee_id = users.id
          FROM users
          WHERE users.slack_team_id = sparkles.slack_team_id AND users.slack_id = sparkles.slack_sparklee_id;

          UPDATE sparkles
          SET sparkler_id = users.id
          FROM users
          WHERE users.slack_team_id = sparkles.slack_team_id AND users.slack_id = sparkles.slack_sparkler_id;

          UPDATE sparkles
          SET channel_id = channels.id
          FROM channels
          WHERE channels.slack_team_id = sparkles.slack_team_id AND channels.slack_id = sparkles.slack_channel_id;
        SQL
      end

      dir.down {} # No-op
    end
  end
end
