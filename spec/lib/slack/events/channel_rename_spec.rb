require "rails_helper"

RSpec.describe Slack::Events::ChannelRename do
  let(:payload) { event_fixture("channel_rename") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel][:id]) }

  it "updates the channel's name" do
    expect {
      Slack::Events::ChannelRename.execute(slack_team_id: team.slack_id, payload: payload[:event])
    }.to change {
      channel.reload.name
    }.to("test-renamed")
  end
end
