require "rails_helper"

RSpec.describe Slack::EventsController, type: :request do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

  describe "POST /slack/events" do
    before do
      allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
    end

    describe "reaction_added" do
      let(:params) do
        {
          token: SecureRandom.base58,
          team_id: team.id,
          api_app_id: "A02N01LRHLP",
          event: {
            type: "reaction_added",
            user: "U02JE49NDNY",
            reaction: "sparkle",
            item: {
              type: "message",
              channel: "C02NCMN16PQ",
              ts: "1722179966.261999"
            },
            item_user: "U02JE49NDNY",
            event_ts: "1722181001.002000"
          },
          type: "event_callback",
          event_id: "Ev07F2JY298Q",
          event_time: 1722181001
        }
      end

      it "enqueues a SparkleJob" do
        expect {
          post slack_events_path, params: params
        }.to have_enqueued_job(SparkleJob).with(
          team_id: team.id,
          recipient_id: "U02JE49NDNY",
          user_id: "U02JE49NDNY",
          channel_id: "C02NCMN16PQ",
          reaction_to_ts: "1722179966.261999"
        )

        expect(response).to have_http_status(:ok)
      end

      context "with a non-sparkle reaction" do
        before do
          params[:event][:reaction] = "thumbsup"
        end

        it "does not enqueue a SparkleJob" do
          expect {
            post slack_events_path, params: params
          }.not_to have_enqueued_job(SparkleJob)

          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe "app_uninstalled" do
      let(:params) do
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
      end

      it "deactivates the team" do
        expect {
          post slack_events_path, params: params
        }.to change {
          team.reload.active
        }.from(true).to(false)
      end
    end

    context "with an unhandled event type" do
      let(:params) do
        {
          token: SecureRandom.base58,
          team_id: team.id,
          api_app_id: "A02N01LRHLP",
          event: {type: "app_mention"},
          type: "event_callback",
          event_id: "Ev12345678",
          event_time: Time.now.to_i
        }
      end

      it "responds with a 400" do
        post slack_events_path, params: params

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
