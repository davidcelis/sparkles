require "rails_helper"

RSpec.describe Slack::Events::GroupRename do
  let(:payload) { event_fixture("group_rename") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel][:id], private: true) }

  it "updates the channel's name" do
    expect {
      Slack::Events::GroupRename.execute(slack_team_id: team.slack_id, payload: payload[:event])
    }.to change {
      channel.reload.name
    }.to("test-renamed")
  end
end
