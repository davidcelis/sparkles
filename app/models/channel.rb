class Channel < ApplicationRecord
  belongs_to :team, primary_key: "slack_id", foreign_key: "slack_team_id"

  def supports_sparkles?
    return false if archived? || shared? || read_only?

    true
  end
end
