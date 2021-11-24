require "rails_helper"

RSpec.describe Slack::Events::ChannelUnarchive do
  let(:payload) { event_fixture("channel_unarchive") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel], archived: true) }

  it "updates the channel's archived flag" do
    expect {
      Slack::Events::ChannelUnarchive.execute(slack_team_id: team.slack_id, payload: payload[:event])
    }.to change {
      channel.reload.archived?
    }.from(true).to(false)
  end
end
