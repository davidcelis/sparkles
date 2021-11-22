require "rails_helper"

RSpec.describe Slack::CommandsController, type: :request do
  describe "POST /slack/commands/" do
    before { allow_any_instance_of(Slack::Events::Request).to receive(:verify!) }

    let(:team) { create(:team, :sparkles) }
    let(:channel) { create(:channel, team: team) }
    let(:user) { create(:user, team: team) }

    let(:text) { "help" }
    let(:params) {
      {
        token: SecureRandom.base58,
        team_id: team.slack_id,
        team_domain: "sparkles",
        channel_id: channel.slack_id,
        channel_name: channel.name,
        user_id: user.slack_id,
        user_name: user.username,
        command: "/sparkle",
        text: text,
        api_app_id: "A#{generate(:slack_id)}",
        is_enterprise_install: "false",
        response_url: "https://hooks.slack.com/commands/respond-here",
        trigger_id: SecureRandom.uuid
      }
    }

    describe "/sparkle @user" do
      context "with a reason" do
        let(:text) { "<@#{user.slack_id}> for always being there for me" }

        it "queues a SparkleWorker with the provided reason" do
          expect(SparkleWorker).to receive(:perform_async).with({
            slack_team_id: params[:team_id],
            slack_channel_id: params[:channel_id],
            slack_sparkler_id: params[:user_id],
            slack_sparklee_id: user.slack_id,
            reason: "for always being there for me"
          })

          post slack_commands_path, params: params
        end
      end

      context "for no reason" do
        let(:text) { "<@#{user.slack_id}>" }

        it "queues a SparkleWorker with a nil reason" do
          expect(SparkleWorker).to receive(:perform_async).with({
            slack_team_id: params[:team_id],
            slack_channel_id: params[:channel_id],
            slack_sparkler_id: params[:user_id],
            slack_sparklee_id: user.slack_id,
            reason: nil
          })

          post slack_commands_path, params: params
        end
      end
    end

    describe "/sparkle stats" do
      context "with no provided user" do
        let(:text) { "stats" }

        it "queues a StatsWorker for team-wide stats" do
          expect(StatsWorker).to receive(:perform_async).with({
            slack_team_id: params[:team_id],
            slack_user_id: nil,
            slack_caller_id: params[:user_id],
            response_url: params[:response_url]
          })

          post slack_commands_path, params: params
        end
      end

      context "with a provided user" do
        let(:text) { "stats <@#{user.slack_id}>" }

        it "queues a StatsWorker with the specified user ID" do
          expect(StatsWorker).to receive(:perform_async).with({
            slack_team_id: params[:team_id],
            slack_user_id: user.slack_id,
            slack_caller_id: params[:user_id],
            response_url: params[:response_url]
          })

          post slack_commands_path, params: params
        end
      end
    end

    describe "/sparkle settings" do
      let(:text) { "settings" }

      # The results of this command are a huge, complicted JSON blob to create
      # a BlockKit view for Slack, so this test just asserts that we create
      # our command with the right arguments and call `execute`
      it "uses the trigger ID to open a modal" do
        expect(Slack::SlashCommands::Settings).to receive(:execute)
          .with(params)
          .and_return(Slack::SlashCommands::Result.new(response_type: nil))

        post slack_commands_path, params: params
        expect(response.status).to eq(200)
        expect(response.body).to be_empty
      end
    end

    describe "/sparkle help" do
      let(:text) { "help" }

      it "responds with the usage text" do
        post slack_commands_path, params: params

        expect(response.body).to eq({
          response_type: :ephemeral,
          text: "Welcome to Sparkles! I'd be happy to get you started :sparkles:\n\n#{Slack::SlashCommands::Help::TEXT}"
        }.to_json)
      end
    end

    context "when the supplied text does not match a known sub-command" do
      let(:text) { "nope" }

      it "returns an error and usage text from /sparkle help" do
        post slack_commands_path, params: params

        expect(response.body).to include("Sorry, I didn't understand your command. Usage:")
        expect(response.body).to include(Slack::SlashCommands::Help::TEXT)
      end
    end

    context "when used in a private slack channel that Sparkles hasn't been added to" do
      before { params[:channel_id] = "C0123456789" }

      it "returns an error" do
        post slack_commands_path, params: params

        expect(response.body).to eq({response_type: :ephemeral, text: "Oops! You need to `/invite` me to this channel before I can work here :sweat_smile:"}.to_json)
      end
    end

    context "when the slack channel doesn't support sparkles" do
      let(:channel) { create(:channel, team: team, shared: true) }

      it "returns an error" do
        post slack_commands_path, params: params

        expect(response.body).to eq({response_type: :ephemeral, text: "Sorry, but I don't work in shared or read-only channels :sweat:"}.to_json)
      end
    end

    context "when slack verification fails due to an expired timestamp" do
      before do
        allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
          .and_raise(Slack::Events::Request::TimestampExpired)
      end

      it "returns an error" do
        post slack_commands_path, params: params

        expect(response.body).to eq("Oops! I ran into an error verifying this request, but you should try again in a sec.")
      end
    end
  end
end
