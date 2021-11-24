require "rails_helper"

RSpec.describe Slack::Events::EmojiChanged do
  let(:payload) { event_fixture("emoji_changed") }
  let(:team) { create(:team, :sparkles) }

  it "busts a team's emoji cache" do
    cache = Mocktail.of_next(EmojiCache)
    stubs { cache.bust! }

    Slack::Events::EmojiChanged.execute(slack_team_id: team.slack_id, payload: payload[:event])
    verify { cache.bust! }
  end
end
