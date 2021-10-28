class Channel < ApplicationRecord
  belongs_to :team, primary_key: "slack_id", foreign_key: "slack_team_id"
end
