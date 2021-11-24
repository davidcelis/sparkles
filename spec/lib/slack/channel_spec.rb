require "rails_helper"

RSpec.describe Slack::Channel do
  let(:response) { request_fixture("conversations_info") }

  describe ".from_api_response" do
    it "initializes a channel from an API response" do
      channel = Slack::Channel.from_api_response(response[:channel], slack_team_id: "T02K1HUQ60Y")

      expect(channel.slack_team_id).to eq("T02K1HUQ60Y")
      expect(channel.slack_id).to eq("C02J565A4CE")
      expect(channel.name).to eq("general")
      expect(channel).not_to be_private
      expect(channel).not_to be_shared
      expect(channel).not_to be_archived
      expect(channel).not_to be_read_only
    end
  end

  describe "#attributes" do
    let(:channel) { Slack::Channel.from_api_response(response[:channel], slack_team_id: "T02K1HUQ60Y") }

    it "returns a hash of translated attributes suitable for local storage" do
      expect(channel.attributes).to eq({
        slack_team_id: "T02K1HUQ60Y",
        slack_id: "C02J565A4CE",
        name: "general",
        private: false,
        archived: false,
        shared: false,
        read_only: false
      })
    end
  end

  describe "#sparklebot_should_join?" do
    let(:channel) { Slack::Channel.from_api_response(response[:channel], slack_team_id: "T02K1HUQ60Y") }
    subject { channel.sparklebot_should_join? }

    context "with a normal public channel" do
      it { is_expected.to be_truthy }
    end

    context "with a private channel" do
      before { channel.private = true }

      it { is_expected.to be_falsy }
    end

    context "with a shared channel" do
      before { channel.shared = true }

      it { is_expected.to be_falsy }
    end

    context "with a archived channel" do
      before { channel.archived = true }

      it { is_expected.to be_falsy }
    end

    context "with a read-only channel" do
      before { channel.read_only = true }

      it { is_expected.to be_falsy }
    end
  end
end
