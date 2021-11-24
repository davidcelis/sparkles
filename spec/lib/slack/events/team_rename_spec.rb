require "rails_helper"

RSpec.describe Slack::Events::TeamRename do
  let(:payload) { event_fixture("team_rename") }
  let!(:team) { create(:team, :sparkles) }

  subject(:event) { Slack::Events::TeamRename.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "updates the team's name" do
    expect { event }.to change { team.reload.name }.to("New Sparkles")
  end
end
