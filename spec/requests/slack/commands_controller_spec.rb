require "rails_helper"

RSpec.describe Slack::CommandsController, type: :request do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

  describe "POST /slack/commands" do
    before do
      allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
    end

    let(:params) {
      {
        token: SecureRandom.base58,
        team_id: team.id,
        team_domain: "sparkles-lol",
        channel_id: "C02J565A4CE",
        channel_name: "general",
        user_id: "U02JE49NDNY",
        user_name: "davidcelis",
        command: command,
        text: text,
        api_app_id: "A02N01LRHLP",
        is_enterprise_install: "false",
        response_url: "https://hooks.slack.com/commands/#{team.id}/respond/here",
        trigger_id: "7440325491831.2647606822032.9a375190d6d176398ffa83e1d7f15d8e"
      }
    }

    describe "/sparkle" do
      let(:command) { "/sparkle" }

      context "when a response is required" do
        let(:text) { "help" }

        it "responds with an ephemeral message" do
          expect(Slack::Commands::Sparkle).to receive(:execute).with(params.except(:command)).and_call_original

          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: Slack::Commands::Sparkle::HELP_TEXT,
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when a valid user ID is provided" do
        let(:text) { "<@U02K7AUR7LN>" }
        let!(:scheduled_message) do
          stub_request(:post, "https://slack.com/api/chat.scheduleMessage")
            .with(body: {channel: "C02J565A4CE", post_at: 1.month.from_now.to_i, text: "Test!"})
            .to_return(status: 200, body: {ok: true, channel: "C02J565A4CE", scheduled_message_id: "Q1298393284"}.to_json)
        end

        it "responds with a 200 and makes the original message visible" do
          expect(Slack::Commands::Sparkle).to receive(:execute).with(params.except(:command)).and_call_original

          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({response_type: :in_channel}.to_json)
        end
      end
    end

    describe "/sparkles" do
      let(:command) { "/sparkles" }
      let(:text) { "" }

      before do
        stub_request(:post, "https://slack.com/api/views.open")
          .to_return(status: 200, body: {ok: true}.to_json)
      end

      it "executes the Sparkles command" do
        expect(Slack::Commands::Sparkles).to receive(:execute).with(params.except(:command)).and_call_original

        post slack_commands_path, params: params

        expect(response).to have_http_status(:accepted)
        expect(response.body).to be_empty
      end
    end
  end
end
