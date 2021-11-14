require "rails_helper"

RSpec.describe Sparkle, type: :model do
  let(:sparkle) { build(:sparkle) }

  describe "#visible_to?" do
    let(:user) { build(:user, team: sparkle.team) }
    subject { sparkle.visible_to?(user) }

    it { is_expected.to be(true) }

    context "when the channel is private" do
      let(:channel) { build(:channel, private: true) }
      let(:sparkle) { build(:sparkle, team: channel.team, channel: channel) }

      context "when the user is the sparkle's recipient" do
        let(:user) { sparkle.sparklee }

        it { is_expected.to be(true) }
      end

      context "when the user is the person who gave the sparkle" do
        let(:user) { sparkle.sparkler }

        it { is_expected.to be(true) }
      end

      context "when the user is not related to the sparkle" do
        let(:user) { build(:user, team: sparkle.team) }

        it { is_expected.to be(false) }
      end
    end

    context "when the user is not in the same team" do
      let(:user) { build(:user) }

      it { is_expected.to be(false) }
    end
  end
end
