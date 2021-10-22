class User < ApplicationRecord
  belongs_to :team
  has_many :sparkles, inverse_of: :sparklee, foreign_key: :sparklee_id
end
