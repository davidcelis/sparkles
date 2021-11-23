require "rails_helper"

RSpec.describe PagesController, type: :request do
  describe "GET /" do
    context "when unauthenticated" do
      it "loads the welcome page and preps for an OAuth or OpenID handshake" do
        expect(cookies[:state]).to be_blank
        expect(cookies[:nonce]).to be_blank

        get root_path

        expect(cookies[:state]).to be_present
        expect(cookies[:nonce]).to be_present
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "redirects to the team stats path" do
        get root_path

        expect(response).to redirect_to(team_stats_path(user.slack_team_id))
      end
    end
  end
end
