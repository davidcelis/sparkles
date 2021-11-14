require "rails_helper"

RSpec.describe Channel, type: :model do
  let(:channel) { build(:channel) }

  describe "#supports_sparkles?" do
    subject { channel.supports_sparkles? }

    it { is_expected.to be(true) }

    context "when the channel is archived" do
      let(:channel) { build(:channel, archived: true) }

      it { is_expected.to be(false) }
    end

    context "when the channel is deleted" do
      let(:channel) { build(:channel, deleted: true) }

      it { is_expected.to be(false) }
    end

    context "when the channel is shared" do
      let(:channel) { build(:channel, shared: true) }

      it { is_expected.to be(false) }
    end

    context "when the channel is read-only" do
      let(:channel) { build(:channel, read_only: true) }

      it { is_expected.to be(false) }
    end
  end
end
