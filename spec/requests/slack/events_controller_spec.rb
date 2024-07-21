require "rails_helper"

RSpec.describe Slack::EventsController, type: :request do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

  describe "POST /slack/events" do
    before do
      allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
    end

    describe "app_uninstalled" do
      let(:params) {
        {
          token: SecureRandom.base58,
          team_id: team.id,
          api_app_id: "A02N01LRHLP",
          event: {
            type: "app_uninstalled"
          },
          type: "event_callback",
          event_id: "Ev12345678",
          event_time: Time.now.to_i
        }
      }

      it "deactivates the team" do
        expect {
          post slack_events_path, params: params
        }.to change {
          team.reload.active
        }.from(true).to(false)
      end
    end
  end
end
