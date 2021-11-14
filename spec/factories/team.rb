FactoryBot.define do
  factory :team do
    slack_id { "T#{generate(:slack_id)}" }
    slack_token { "<SLACK_TOKEN>" }
    name { Faker::App.name }
    icon_url { Faker::Avatar.image }
    sparklebot_id { "U#{generate(:slack_id)}" }

    trait :sparkles do
      slack_id { "T02K1HUQ60Y" }
      name { "Sparkles" }
      icon_url { "https://avatars.slack-edge.com/2021-10-23/2642530172644_b1f7592ed7472c2dfb0e_original.png" }
      sparklebot_id { "U02JEBH6BGC" }
    end
  end
end
