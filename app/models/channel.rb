class Channel < ApplicationRecord
  belongs_to :team, primary_key: "slack_id", foreign_key: "slack_team_id"

  def supports_sparkles?
    !(archived? || deleted? || shared? || read_only?)
  end
end
