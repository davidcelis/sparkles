require "rails_helper"

RSpec.describe Slack::Events::ChannelArchive do
  let(:payload) { event_fixture("channel_archive") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel]) }

  subject(:event) { Slack::Events::ChannelArchive.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "updates the channel's archived flag" do
    expect { event }.to change { channel.reload.archived? }.from(false).to(true)
  end
end
