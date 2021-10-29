FactoryBot.define do
  factory :sparkle do
    association :team
    association :sparklee, factory: :user
    association :sparkler, factory: :user
    association :channel
  end
end
