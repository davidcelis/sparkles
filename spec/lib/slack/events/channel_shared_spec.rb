require "rails_helper"

RSpec.describe Slack::Events::ChannelShared do
  let(:payload) { event_fixture("channel_shared") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel]) }

  subject(:event) { Slack::Events::ChannelShared.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "updates the channel's shared flag" do
    VCR.use_cassette("channel_shared_event") do
      expect { event }.to change { channel.reload.shared? }.from(false).to(true)
    end
  end
end
