class Sparkle < ApplicationRecord
  belongs_to :team, primary_key: "slack_id", foreign_key: "slack_team_id"
  belongs_to :sparklee, class_name: "User", primary_key: "slack_id", foreign_key: "slack_sparklee_id", counter_cache: true
  belongs_to :sparkler, class_name: "User", primary_key: "slack_id", foreign_key: "slack_sparkler_id"
  belongs_to :channel, primary_key: "slack_id", foreign_key: "slack_channel_id"

  def visible_to?(user)
    return true unless channel.private?

    # We don't track channel membership, so if the sparkle happened in a
    # private channel, we'll only show it to the sparkler or sparklee.
    user.slack_id.in?([slack_sparklee_id, slack_sparkler_id])
  end
end
