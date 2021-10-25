class Sparkle < ApplicationRecord
  belongs_to :sparklee, class_name: "User", foreign_key: "sparklee_id", counter_cache: true
  belongs_to :sparkler, class_name: "User", foreign_key: "sparkler_id"
  belongs_to :channel
end
