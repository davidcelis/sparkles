FactoryBot.define do
  factory :user do
    association :team

    slack_id { "U#{SecureRandom.base36(10).upcase}" }
    name { Faker::Name.name }
    username { Faker::Internet.username }
    image_url { Faker::Avatar.image }
    deactivated { false }

    trait :davidcelis do
      slack_id { "U02JE49NDNY" }
      name { "David Celis" }
      username { "davidcelis" }
      image_url { "https://secure.gravatar.com/avatar/66b085a6f16864adae78586e92811a73.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0002-512.png" }

      association :team, :sparkles
    end

    # Our test Slack users
    trait :bright_idea do
      slack_id { "U02JZCB1U5D" }
      name { "Bright Idea" }
      username { "Bright Idea" }
      image_url { "https://secure.gravatar.com/avatar/5b86674546169c25a1e0f55b41110a42.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0002-512.png" }

      association :team, :sparkles
    end

    trait :kind_bed do
      slack_id { "U02KE361RNF" }
      name { "Kind Bed" }
      username { "Kind Bed" }
      image_url { "https://secure.gravatar.com/avatar/40b56128669324521476518b6cb7f708.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0012-512.png" }

      association :team, :sparkles
    end

    trait :quiet_spot do
      slack_id { "U02K7AUR7LN" }
      name { "Quiet Spot" }
      username { "Quiet Spot" }
      image_url { "https://secure.gravatar.com/avatar/b8c7d6bffb496e1d9f9a9e3038f2464d.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0020-512.png" }

      association :team, :sparkles
    end

    trait :small_coffee do
      slack_id { "U02KG93ESUU" }
      name { "Small Coffee" }
      username { "Small Coffee" }
      image_url { "https://secure.gravatar.com/avatar/585d522c09befbdd580558c7a4e3aa5f.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0024-512.png" }

      association :team, :sparkles
    end
  end
end
