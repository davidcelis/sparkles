require "rails_helper"

RSpec.describe Team, type: :model do
  let(:team) { build(:team) }

  describe "#api_client" do
    subject(:api_client) { team.api_client }

    it "initializes a Slack::Web::Client with the team's token" do
      expect(api_client.token).to eq(team.slack_token)
    end
  end
end
