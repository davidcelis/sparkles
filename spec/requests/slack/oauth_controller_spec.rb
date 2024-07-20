require "rails_helper"

RSpec.describe Slack::OAuthController, type: :request do
  describe "GET /slack/oauth/callback" do
    let(:state) { SecureRandom.urlsafe_base64 }
    let(:code) { "<SLACK_OAUTH_CODE>" }

    before { cookies[:state] = state }

    context "when the state does not match" do
      it "returns an error" do
        get slack_oauth_callback_path, params: {code: code, state: "nope"}

        expect(flash[:alert]).to eq("The provided OAuth state did not match. Please try installing to Slack again.")
        expect(response).to redirect_to(root_path)
      end
    end

    context "when installing for the first time" do
      around { |e| VCR.use_cassette("slack_oauth_callback", &e) }

      it "adds the Team to the database" do
        expect {
          get slack_oauth_callback_path, params: {code: code, state: state}
        }.to change {
          Team.count
        }.by(1)

        team = Team.last
        expect(team.id).to eq("T02K1HUQ60Y")
        expect(team.name).to eq("Sparkles")
        expect(team.sparklebot_id).to eq("USPARKLEBOT")
        expect(team.access_token).to eq("<SLACK_TOKEN>")
        expect(team).to be_active
      end
    end

    context "when reinstalling" do
      let!(:team) { Team.create!(id: "T02K1HUQ60Y", name: "Old Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<OLD_TOKEN>", active: false) }

      around { |e| VCR.use_cassette("slack_oauth_callback", &e) }

      it "updates the team's information and access token" do
        expect {
          get slack_oauth_callback_path, params: {code: code, state: state}
        }.not_to change { Team.count }

        team.reload
        expect(team.name).to eq("Sparkles")
        expect(team.access_token).to eq("<SLACK_TOKEN>")
        expect(team).to be_active
      end
    end
  end
end
