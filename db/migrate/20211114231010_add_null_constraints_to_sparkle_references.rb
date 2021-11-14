class AddNullConstraintsToSparkleReferences < ActiveRecord::Migration[6.1]
  def change
    change_column_null :sparkles, :sparklee_id, false
    change_column_null :sparkles, :sparkler_id, false
    change_column_null :sparkles, :channel_id, false
  end
end
