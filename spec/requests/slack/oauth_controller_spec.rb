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
      around do |example|
        VCR.use_cassette("slack_oauth_callback") { example.run }
      end

      it "creates a new Team and syncs their data" do
        expect {
          get slack_oauth_callback_path, params: {code: code, state: state}
        }.to change { Team.count }.by(1)
          .and change { SyncSlackTeamWorker.jobs.size }.by(1)

        team = Team.last
        expect(team.slack_id).to eq("T02K1HUQ60Y")
        expect(team.name).to eq("Sparkles")
        expect(team.icon_url).to eq("https://avatars.slack-edge.com/2021-10-23/2642530172644_b1f7592ed7472c2dfb0e_original.png")
        expect(team.sparklebot_id).to eq("USPARKLEBOT")
        expect(team.slack_token).to eq("<SLACK_TOKEN>")

        job = SyncSlackTeamWorker.jobs.last
        expect(job["args"]).to eq([team.id, true])
      end

      it "creates and signs in the authorizing user" do
        expect {
          get slack_oauth_callback_path, params: {code: code, state: state}
        }.to change { User.count }.by(1)

        user = User.last
        expect(user.slack_team_id).to eq("T02K1HUQ60Y")
        expect(user.slack_id).to eq("U02JE49NDNY")
        expect(user.name).to eq("David Celis")
        expect(user.username).to eq("David")
        expect(user.image_url).to eq("https://secure.gravatar.com/avatar/66b085a6f16864adae78586e92811a73.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0002-512.png")
        expect(user).not_to be_deactivated
        expect(user).to be_team_admin

        expect(cookies[:slack_team_id]).to eq(user.slack_team_id)
        expect(cookies[:slack_user_id]).to eq(user.slack_id)
      end
    end

    context "when installing again" do
      let!(:team) { create(:team, :sparkles, slack_token: "<OLD_TOKEN>", name: "Old Sparkles", uninstalled: true) }
      let!(:user) { create(:user, team: team, slack_id: "U02JE49NDNY", name: "David S. Pumpkins") }

      around do |example|
        VCR.use_cassette("slack_oauth_callback") { example.run }
      end

      it "updates the team's information and access token" do
        expect {
          get slack_oauth_callback_path, params: {code: code, state: state}
        }.not_to change { Team.count }

        team.reload
        expect(team.slack_token).to eq("<SLACK_TOKEN>")
        expect(team.name).to eq("Sparkles")
        expect(team).not_to be_uninstalled
      end

      it "signs in and updates the authorizing user" do
        expect {
          get slack_oauth_callback_path, params: {code: code, state: state}
        }.not_to change { User.count }

        user.reload
        expect(user.name).to eq("David Celis")
        expect(cookies[:slack_team_id]).to eq(user.slack_team_id)
        expect(cookies[:slack_user_id]).to eq(user.slack_id)
      end
    end
  end
end
