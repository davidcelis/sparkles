class Sparkle < ApplicationRecord
  belongs_to :sparklee, class_name: "User", counter_cache: true
  belongs_to :sparkler, class_name: "User"
  belongs_to :channel

  def visible_to?(user)
    # Sparkles aren't visible across separate teams
    return false unless user.slack_team_id == sparklee.slack_team_id

    # Sparkles in public channels are always visible
    return true unless channel.private?

    # We don't track channel membership, so if the sparkle happened in a
    # private channel, we'll only show it to the sparklee or sparkler.
    user == sparklee || user == sparkler
  end
end
