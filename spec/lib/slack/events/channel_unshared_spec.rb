require "rails_helper"

RSpec.describe Slack::Events::ChannelUnshared do
  let(:payload) { event_fixture("channel_unshared") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel], shared: true) }

  subject(:event) { Slack::Events::ChannelUnshared.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "updates the channel's shared flag" do
    VCR.use_cassette("channel_unshared_event") do
      expect { event }.to change { channel.reload.shared? }.from(true).to(false)
    end
  end
end
