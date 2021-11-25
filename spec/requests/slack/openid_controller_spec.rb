require "rails_helper"

RSpec.describe Slack::OAuthController, type: :request do
  describe "GET /slack/openid/callback" do
    let(:id_token) { "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1CMk1BeUtTbjU1NWlzZDBFYmRoS3g2bmt5QWk5eExxOHJ2Q0ViX25PeVkifQ.eyJpc3MiOiJodHRwczpcL1wvc2xhY2suY29tIiwic3ViIjoiVTAySkU0OU5ETlkiLCJhdWQiOiIyNjQ3NjA2ODIyMDMyLjI2NDc2MTkxNDIwODAiLCJleHAiOjE2MzY2NjQ2MzksImlhdCI6MTYzNjY2NDMzOSwiYXV0aF90aW1lIjoxNjM2NjY0MzM5LCJub25jZSI6IjF1SzdjZm1HRnlnUDFsaDJhbm5uaFEiLCJhdF9oYXNoIjoiaVJvb1hzNmxKdmF4NkMtNFRKd09TUSIsImh0dHBzOlwvXC9zbGFjay5jb21cL3RlYW1faWQiOiJUMDJLMUhVUTYwWSIsImh0dHBzOlwvXC9zbGFjay5jb21cL3VzZXJfaWQiOiJVMDJKRTQ5TkROWSJ9.xvZncMHNgLLMnSCpEGN6FAvxLIUVXgsbCTLHETbV56IfGwKLmuRGko2QMWrUC75XOgnuh9cwuOcVk-pGJsXINd3eJH22J_cB7gMFw9swormDn8Mt4umSi6SUbT2MGNmQcUfvuWtEjnCu1p_Imetd3pYjDVFAch6eg03veAbujnjk9psvvJ5VrBsAUFDDC2akiQjjY3soTOkqqwQGpaKRNL1N_5eIvTisuN-bFrQjEVnrvBm1iKbdit6J2S7ZWVbC-N-W1FQht1Mlzt_7WzpSvUnF9Q2wybN4QDp7CuwfsFB6zL_zd0JQEU5ZTK2r4i1cQpCJq7ah3lyDa2i2SyW9yw" }
    let(:jwt) { JWT.decode(id_token, nil, false).first }
    let(:state) { SecureRandom.urlsafe_base64 }
    let(:nonce) { jwt["nonce"] }
    let(:code) { "<SLACK_OAUTH_CODE>" }

    before do
      cookies[:state] = state
      cookies[:nonce] = nonce
    end

    it "returns an error when the state does not match" do
      VCR.use_cassette("slack_openid_callback") do
        get slack_openid_callback_path, params: {code: code, state: "nope"}
      end

      expect(flash[:alert]).to eq("The provided OpenID state did not match. Please try signing in again.")
      expect(response).to redirect_to(root_path)
    end

    it "returns an error when the nonce does not match" do
      cookies[:nonce] = "nope"

      VCR.use_cassette("slack_openid_callback") do
        get slack_openid_callback_path, params: {code: code, state: state}
      end

      expect(flash[:alert]).to eq("The provided OpenID nonce did not match. Please try signing in again.")
      expect(response).to redirect_to(root_path)
    end

    it "returns an error when the user's team has not installed Sparkles yet" do
      VCR.use_cassette("slack_openid_callback") do
        get slack_openid_callback_path, params: {code: code, state: state}
      end

      expect(flash[:alert]).to eq("Oops, your team hasn't installed Sparkles yet! Use the \"Add to Slack\" button to get it installed before trying to sign in.")
      expect(response).to redirect_to(root_path)
    end

    context "when the team has installed Sparkles" do
      let!(:team) { create(:team, :sparkles) }

      context "when the user has not been created yet" do
        around do |example|
          VCR.use_cassette("slack_openid_callback_without_existing_user") { example.run }
        end

        it "creates and signs in the user" do
          expect {
            get slack_openid_callback_path, params: {code: code, state: state}
          }.to change { User.count }.by(1)

          user = User.last
          expect(user.slack_team_id).to eq(team.slack_id)
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

      context "when the user has already been created" do
        let!(:user) { create(:user, team: team, slack_id: "U02JE49NDNY") }

        around do |example|
          VCR.use_cassette("slack_openid_callback") { example.run }
        end

        it "signs in the user" do
          expect {
            get slack_openid_callback_path, params: {code: code, state: state}
          }.not_to change { User.count }

          expect(cookies[:slack_team_id]).to eq(user.slack_team_id)
          expect(cookies[:slack_user_id]).to eq(user.slack_id)
        end
      end

      context "when the team has later uninstalled sparkles" do
        before { team.update!(uninstalled: true) }

        it "returns an error" do
          VCR.use_cassette("slack_openid_callback") do
            get slack_openid_callback_path, params: {code: code, state: state}
          end

          expect(flash[:alert]).to eq("Sorry, your team uninstalled Sparkles. They'll have to reinstall it if you want to sign in with this team. If they do reinstall, all of your sparkles are still here!")
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
