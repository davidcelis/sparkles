class Sparkle < ApplicationRecord
  belongs_to :team, primary_key: "slack_id", foreign_key: "slack_team_id"
  belongs_to :sparklee, class_name: "User", primary_key: "slack_id", foreign_key: "slack_sparklee_id", counter_cache: true
  belongs_to :sparkler, class_name: "User", primary_key: "slack_id", foreign_key: "slack_sparkler_id"
  belongs_to :channel, primary_key: "slack_id", foreign_key: "slack_channel_id"
end
