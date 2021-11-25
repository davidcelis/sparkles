require "rails_helper"

RSpec.describe Slack::SlashCommands::Result do
  let(:response_type) { :ephemeral }
  let(:text) { ":sparkles: Hello world :sparkles:" }
  let(:result) { Slack::SlashCommands::Result.new(response_type: response_type, text: text) }

  describe "#should_render?" do
    subject { result.should_render? }

    context "with an ephemeral response type" do
      let(:response_type) { :ephemeral }

      it { is_expected.to be_truthy }
    end

    context "with an in-channel response type" do
      let(:response_type) { :in_channel }

      it { is_expected.to be_truthy }
    end

    context "with no response type" do
      let(:response_type) { nil }

      it { is_expected.to be_falsey }
    end
  end

  describe "#as_json" do
    it "returns a hash suitable for BlockKit" do
      expect(result.to_json).to eq({response_type: response_type, text: text}.to_json)
    end
  end
end
