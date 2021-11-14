FactoryBot.define do
  factory :sparkle do
    association :team

    sparklee { association :user, team: team }
    sparkler { association :user, team: team }

    association :channel

    reason { "for #{Faker::Fantasy::Tolkien.poem}" }
  end
end
