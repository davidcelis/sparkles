require "rails_helper"

RSpec.describe Slack::EventsController, type: :request do
  describe "POST /slack/events/" do
    before { allow_any_instance_of(Slack::Events::Request).to receive(:verify!) }

    let(:params) { event_fixture(:user_change) }

    it "calls the proper event handler" do
      expect(Slack::Events::UserChange).to receive(:execute)
        .with(slack_team_id: params[:team_id], payload: params[:event])

      post slack_events_path, params: params, as: :json
      expect(response.status).to eq(200)
      expect(response.body).to be_empty
    end

    context "with a url_verification event" do
      let(:params) { event_fixture(:url_verification) }

      it "responds with the challenge" do
        post slack_events_path, params: params, as: :json

        expect(response.status).to eq(200)
        expect(response.content_type).to eq("text/plain; charset=utf-8")
        expect(response.body).to eq(params[:challenge])
      end
    end

    context "when slack verification fails" do
      before do
        allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
          .and_raise(Slack::Events::Request::InvalidSignature)
      end

      it "is a bad request" do
        post slack_events_path, params: params, as: :json

        expect(response.status).to eq(400)
      end
    end
  end
end
