class User < ApplicationRecord
  belongs_to :team, primary_key: "slack_id", foreign_key: "slack_team_id"

  has_many :sparkles, primary_key: "slack_id", foreign_key: "slack_sparklee_id", inverse_of: :sparklee
end
