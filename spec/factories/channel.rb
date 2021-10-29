FactoryBot.define do
  factory :channel do
    association :team

    slack_id { "C#{SecureRandom.base36(10).upcase}" }
    name { Faker::Internet.slug }
    archived { false }
    deleted { false }
    add_attribute(:private) { false }

    trait :general do
      association :team, :sparkles

      slack_id { "C02J565A4CE" }
      name { "general" }
    end

    trait :random do
      association :team, :sparkles

      slack_id { "C02JBTVC17D" }
      name { "random" }
    end

    trait :private do
      association :team, :sparkles

      slack_id { "C02JNCRMVPV" }
      name { "private-sparkles" }
      add_attribute(:private) { true }
    end

    trait :archived do
      association :team, :sparkles

      slack_id { "C02KKF8GSHW" }
      name { "to-be-archived" }
      archived { true }
    end
  end
end
