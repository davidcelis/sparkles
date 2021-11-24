require "rails_helper"

RSpec.describe Slack::Events::GroupDeleted do
  let(:payload) { event_fixture("group_deleted") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel], private: true) }

  it "updates the channel's deleted flag" do
    expect {
      Slack::Events::GroupDeleted.execute(slack_team_id: team.slack_id, payload: payload[:event])
    }.to change {
      channel.reload.deleted?
    }.from(false).to(true)
  end
end
