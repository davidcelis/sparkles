require "rails_helper"

RSpec.describe Slack::Events::GroupUnarchive do
  let(:payload) { event_fixture("group_unarchive") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel], archived: true, private: true) }

  subject(:event) { Slack::Events::GroupUnarchive.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "updates the channel's archived flag" do
    expect { event }.to change { channel.reload.archived? }.from(true).to(false)
  end
end
