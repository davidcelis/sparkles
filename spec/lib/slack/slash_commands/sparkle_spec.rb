require "rails_helper"

RSpec.describe Slack::SlashCommands::Sparkle do
  let(:team) { create(:team) }
  let(:channel) { create(:channel, team: team) }
  let(:sparkler) { create(:user, team: team) }
  let(:sparklee) { create(:user, team: team) }

  context "with no reason provided" do
    let(:params) do
      {
        team_id: team.slack_id,
        user_id: sparkler.slack_id,
        channel_id: channel.slack_id,
        text: "<@#{sparklee.slack_id}|#{sparklee.username}>"
      }
    end

    it "queues a SparkleWorker with no reason" do
      expect(SparkleWorker).to receive(:perform_async).with({
        slack_team_id: team.slack_id,
        slack_channel_id: channel.slack_id,
        slack_sparkler_id: sparkler.slack_id,
        slack_sparklee_id: sparklee.slack_id,
        reason: nil
      })

      result = Slack::SlashCommands::Sparkle.execute(params)
      expect(result.response_type).to eq(:in_channel)
      expect(result.text).to be_blank
    end
  end

  context "with a reason provided" do
    let(:params) do
      {
        team_id: team.slack_id,
        user_id: sparkler.slack_id,
        channel_id: channel.slack_id,
        text: "<@#{sparklee.slack_id}|#{sparklee.username}> for always being there for me"
      }
    end

    it "queues a SparkleWorker with the parsed reason" do
      expect(SparkleWorker).to receive(:perform_async).with({
        slack_team_id: team.slack_id,
        slack_channel_id: channel.slack_id,
        slack_sparkler_id: sparkler.slack_id,
        slack_sparklee_id: sparklee.slack_id,
        reason: "for always being there for me"
      })

      result = Slack::SlashCommands::Sparkle.execute(params)
      expect(result.response_type).to eq(:in_channel)
      expect(result.text).to be_blank
    end
  end
end
