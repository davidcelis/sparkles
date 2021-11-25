require "rails_helper"

RSpec.describe Slack::SlashCommands::Stats do
  let(:team) { create(:team) }
  let(:channel) { create(:channel, team: team) }
  let(:user) { create(:user, team: team) }

  context "with no user provided" do
    let(:params) do
      {
        team_id: team.slack_id,
        user_id: user.slack_id,
        channel_id: channel.slack_id,
        text: "stats",
        response_url: "https://api.slack.com/respond_here"
      }
    end

    it "queues a StatsWorker with no user_id provided" do
      expect(StatsWorker).to receive(:perform_async).with({
        slack_team_id: team.slack_id,
        slack_user_id: nil,
        slack_caller_id: user.slack_id,
        response_url: "https://api.slack.com/respond_here"
      })

      result = Slack::SlashCommands::Stats.execute(params)
      expect(result.response_type).to eq(:ephemeral)
      expect(result.text).to be_blank
    end
  end

  context "with a user provided" do
    let(:params) do
      {
        team_id: team.slack_id,
        user_id: user.slack_id,
        channel_id: channel.slack_id,
        text: "stats <@#{user.slack_id}|#{user.username}>",
        response_url: "https://api.slack.com/respond_here"
      }
    end

    it "queues a StatsWorker with the user_id provided" do
      expect(StatsWorker).to receive(:perform_async).with({
        slack_team_id: team.slack_id,
        slack_user_id: user.slack_id,
        slack_caller_id: user.slack_id,
        response_url: "https://api.slack.com/respond_here"
      })

      result = Slack::SlashCommands::Stats.execute(params)
      expect(result.response_type).to eq(:ephemeral)
      expect(result.text).to be_blank
    end
  end
end
