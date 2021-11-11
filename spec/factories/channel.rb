FactoryBot.define do
  factory :channel do
    association :team

    slack_id { "C#{generate(:slack_id)}" }
    name { Faker::Internet.slug }

    add_attribute(:private) { false }
    archived { false }
    deleted { false }
    shared { false }
    read_only { false }
  end
end
