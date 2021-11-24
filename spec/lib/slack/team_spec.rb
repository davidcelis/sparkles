require "rails_helper"

RSpec.describe Slack::Team do
  let(:response) { request_fixture("team_info") }

  describe ".from_api_response" do
    it "initializes a channel from an API response" do
      team = Slack::Team.from_api_response(response[:team])

      expect(team.slack_id).to eq("T02K1HUQ60Y")
      expect(team.name).to eq("Sparkles")
      expect(team.icon_url).to eq("https://avatars.slack-edge.com/2021-10-23/2642530172644_b1f7592ed7472c2dfb0e_original.png")
    end
  end

  describe "#attributes" do
    let(:team) { Slack::Team.from_api_response(response[:team]) }

    it "returns a hash of translated attributes suitable for local storage" do
      expect(team.attributes).to eq({
        slack_id: "T02K1HUQ60Y",
        name: "Sparkles",
        icon_url: "https://avatars.slack-edge.com/2021-10-23/2642530172644_b1f7592ed7472c2dfb0e_original.png"
      })
    end
  end
end
