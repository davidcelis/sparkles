FactoryBot.define do
  factory :sparkle do
    transient do
      team { build(:team) }
    end

    sparklee { association :user, slack_team_id: team.slack_id }
    sparkler { association :user, slack_team_id: team.slack_id }
    channel { association :channel, slack_team_id: team.slack_id }

    reason { "for #{Faker::Fantasy::Tolkien.poem}" }
  end
end
