class DefaultAllTimestampsToNow < ActiveRecord::Migration[6.1]
  TABLES = %i[teams users channels sparkles]
  TIMESTAMPS = %i[created_at updated_at]

  def change
    TABLES.each do |table|
      TIMESTAMPS.each { |ts| change_column_default table, ts, from: nil, to: ->{ "NOW()" } }
    end
  end
end
