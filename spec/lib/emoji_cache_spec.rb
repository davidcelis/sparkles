require "rails_helper"

RSpec.describe EmojiCache do
  let(:team) { create(:team, :sparkles) }

  describe "#bust!" do
    it "clears the team's emoji key" do
      expect(Rails.cache.redis).to receive(:del).with("teams:#{team.slack_id}:emoji")

      EmojiCache.new(team).bust!
    end
  end
end
