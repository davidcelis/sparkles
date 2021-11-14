FactoryBot.define do
  sequence(:slack_id) { Faker::Alphanumeric.alphanumeric(number: 10).upcase }
end
