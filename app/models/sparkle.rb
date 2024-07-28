class Sparkle < ApplicationRecord
  belongs_to :team

  def reaction?
    reaction_to_ts.present?
  end
end
