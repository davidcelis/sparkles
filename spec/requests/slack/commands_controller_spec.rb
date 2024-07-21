require "rails_helper"

RSpec.describe Slack::CommandsController, type: :request do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

  describe "POST /slack/commands" do
    before do
      allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
    end

    describe "/sparkle" do
      let(:text) { "<@U02K7AUR7LN>" }
      let(:params) {
        {
          token: SecureRandom.base58,
          team_id: team.id,
          team_domain: "sparkles-lol",
          channel_id: "C02J565A4CE",
          channel_name: "general",
          user_id: "U02JE49NDNY",
          user_name: "davidcelis",
          command: "/sparkle",
          text: text,
          api_app_id: "A02N01LRHLP",
          is_enterprise_install: "false",
          response_url: "https://hooks.slack.com/commands/#{team.id}/respond/here",
          trigger_id: "7440325491831.2647606822032.9a375190d6d176398ffa83e1d7f15d8e"
        }
      }

      let!(:scheduled_message) do
        stub_request(:post, "https://slack.com/api/chat.scheduleMessage")
          .with(body: {channel: "C02J565A4CE", post_at: 1.month.from_now.to_i, text: "Test!"})
          .to_return(status: 200, body: {ok: true, channel: "C02J565A4CE", scheduled_message_id: "Q1298393284"}.to_json)
      end

      it "enqueues a background job to give a sparkle" do
        expect {
          post slack_commands_path, params: params
        }.to have_enqueued_job(SparkleJob).with(
          team_id: team.id,
          channel_id: params[:channel_id],
          user_id: params[:user_id],
          recipient_id: "U02K7AUR7LN",
          reason: nil,
          response_url: params[:response_url],
          scheduled_message_id: "Q1298393284"
        )
      end

      context "when help is requested" do
        let(:text) { "help" }

        it "responds with a help message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: Slack::Commands::Sparkle::HELP_TEXT,
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when a reason is provided" do
        let(:text) { "<@U02K7AUR7LN> for being awesome" }

        it "provides the reason to the background job" do
          expect {
            post slack_commands_path, params: params
          }.to have_enqueued_job(SparkleJob).with(
            team_id: team.id,
            channel_id: params[:channel_id],
            user_id: params[:user_id],
            recipient_id: "U02K7AUR7LN",
            reason: "for being awesome",
            response_url: params[:response_url],
            scheduled_message_id: "Q1298393284"
          )
        end
      end

      context "when the command is not formatted correctly" do
        let(:text) { "<#C02J565A4CE> lol" }

        it "responds with an error message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: "Sorry, I didn’t understand that.\n\nUsage: `/sparkle @user [reason]`",
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when Sparklebot is not in the channel" do
        before do
          allow_any_instance_of(Slack::Web::Client).to receive(:chat_scheduleMessage).and_raise(Slack::Web::Api::Errors::NotInChannel, "not_in_channel")
        end

        it "responds with an error message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: "Oops! You'll need to `/invite` me to this channel before I can work here :sweat_smile: Here’s that sparkle you tried to give away so you can copy and paste it back!\n\n/sparkle #{text}",
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when an unexpected error occurs" do
        before do
          allow_any_instance_of(Slack::Web::Client).to receive(:chat_scheduleMessage).and_raise(Slack::Web::Api::Errors::FatalError, "fatal_error")
        end

        it "responds with an error message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: "Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime. Here’s that sparkle you tried to give away so you can try again more easily!\n\n/sparkle #{text}",
            response_type: :ephemeral
          }.to_json)
        end
      end
    end

    describe "/sparkles" do
      let(:text) { "" }
      let(:params) {
        {
          token: SecureRandom.base58,
          team_id: team.id,
          team_domain: "sparkles-lol",
          channel_id: "C02J565A4CE",
          channel_name: "general",
          user_id: "U02JE49NDNY",
          user_name: "davidcelis",
          command: "/sparkles",
          text: text,
          api_app_id: "A02N01LRHLP",
          is_enterprise_install: "false",
          response_url: "https://hooks.slack.com/commands/#{team.id}/respond/here",
          trigger_id: "7440325491831.2647606822032.9a375190d6d176398ffa83e1d7f15d8e"
        }
      }

      it "responds with a message that the feature is coming soon" do
        post slack_commands_path, params: params

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq({
          text: ":construction: This feature is coming soon!",
          response_type: :ephemeral
        }.to_json)
      end

      context "when help is requested" do
        let(:text) { "help" }

        it "responds with a help message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: Slack::Commands::Sparkles::HELP_TEXT,
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when the command is not formatted correctly" do
        let(:text) { "lol" }

        it "responds with the help message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: Slack::Commands::Sparkles::HELP_TEXT,
            response_type: :ephemeral
          }.to_json)
        end
      end
    end
  end
end
