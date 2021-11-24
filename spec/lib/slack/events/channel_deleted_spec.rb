require "rails_helper"

RSpec.describe Slack::Events::ChannelDeleted do
  let(:payload) { event_fixture("channel_deleted") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel]) }

  subject(:event) { Slack::Events::ChannelDeleted.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "updates the channel's deleted flag" do
    expect { event }.to change { channel.reload.deleted? }.from(false).to(true)
  end
end
