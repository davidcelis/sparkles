require "rails_helper"

RSpec.describe EmojiCache do
  let(:team) { create(:team, :sparkles) }
  let(:cache) { EmojiCache.new(team) }

  let(:cassette) { YAML.load_file("spec/fixtures/cassettes/emoji_list.yml").with_indifferent_access }
  let(:emoji_response) { request_fixture("emoji_list") }
  let(:cache_key) { "teams:#{team.slack_id}:emoji" }

  describe "#read" do
    context "when no custom emoji are stored" do
      it "hits Slack's Emoji API and returns the requested emoji" do
        expect(Rails.cache.redis).to receive(:hset).with(cache_key, emoji_response[:emoji])
        emoji = VCR.use_cassette("emoji_list") { cache.read("sushi-sparkles", "dark-sparkles") }

        expect(emoji.size).to eq(2)
        expect(emoji["sushi-sparkles"]).to eq("https://emoji.slack-edge.com/T02K1HUQ60Y/sushi-sparkles/93d6a0310ff69dd7.png")
        expect(emoji["dark-sparkles"]).to eq("https://emoji.slack-edge.com/T02K1HUQ60Y/dark-sparkles/71e4bda7ea624a3c.png")
      end
    end

    context "when custom emoji are stored" do
      before do
        stored_emoji = emoji_response[:emoji].slice("sushi-sparkles")
        Rails.cache.redis.hset(cache_key, stored_emoji)
      end

      it "does not hit Slack's Emoji API when no cache misses occur" do
        # This raises an error if we make the API request because we aren't
        # wrapping cache.read in a VCR cassette block.
        emoji = cache.read("sushi-sparkles")
        expect(emoji.size).to eq(1)
        expect(emoji["sushi-sparkles"]).to eq("https://emoji.slack-edge.com/T02K1HUQ60Y/sushi-sparkles/93d6a0310ff69dd7.png")
      end

      it "hits Slack's Emoji API if a cache miss occurs" do
        expect(Rails.cache.redis).to receive(:hset).with(cache_key, emoji_response["emoji"])
        emoji = VCR.use_cassette("emoji_list") { cache.read("sushi-sparkles", "dark-sparkles") }

        expect(emoji.size).to eq(2)
        expect(emoji["sushi-sparkles"]).to eq("https://emoji.slack-edge.com/T02K1HUQ60Y/sushi-sparkles/93d6a0310ff69dd7.png")
        expect(emoji["dark-sparkles"]).to eq("https://emoji.slack-edge.com/T02K1HUQ60Y/dark-sparkles/71e4bda7ea624a3c.png")
      end

      it "does not hit Slack's Emoji API multiple times for repeated cache misses" do
        expect(Rails.cache.redis).to receive(:hset).with(cache_key, emoji_response["emoji"]).once
        first_emoji = VCR.use_cassette("emoji_list") { cache.read("doesnt-exist") }
        expect(first_emoji["doesnt-exist"]).to be_blank

        second_emoji = cache.read("doesnt-exist")
        expect(second_emoji["doesnt-exist"]).to be_blank
      end
    end
  end

  describe "#bust!" do
    it "clears the team's emoji key" do
      expect(Rails.cache.redis).to receive(:del).with(cache_key)

      EmojiCache.new(team).bust!
    end
  end
end
