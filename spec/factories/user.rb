FactoryBot.define do
  factory :user do
    association :team

    slack_id { "U#{generate(:slack_id)}" }
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
  end
end
