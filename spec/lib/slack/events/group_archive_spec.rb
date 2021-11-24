require "rails_helper"

RSpec.describe Slack::Events::GroupArchive do
  let(:payload) { event_fixture("group_archive") }
  let(:team) { create(:team, :sparkles) }
  let!(:channel) { create(:channel, team: team, slack_id: payload[:event][:channel], private: true) }

  subject(:event) { Slack::Events::GroupArchive.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "updates the channel's archived flag" do
    expect { event }.to change { channel.reload.archived? }.from(false).to(true)
  end
end
