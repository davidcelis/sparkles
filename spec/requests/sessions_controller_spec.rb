require "rails_helper"

RSpec.describe PagesController, type: :request do
  describe "DESTROY /sign_out" do
    let(:user) { create(:user) }

    before { sign_in(user) }

    it "clears the user's cookies" do
      expect(cookies[:slack_team_id]).to be_present
      expect(cookies[:slack_user_id]).to be_present

      delete sign_out_path

      expect(cookies[:slack_team_id]).to be_blank
      expect(cookies[:slack_user_id]).to be_blank
    end
  end
end
