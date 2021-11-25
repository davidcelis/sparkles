require "rails_helper"

RSpec.describe Slack::Events::AppUninstalled do
  let(:payload) { event_fixture("app_uninstalled") }
  let(:team) { create(:team, :sparkles) }

  subject(:event) { Slack::Events::AppUninstalled.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "updates the team's uninstalled flag" do
    expect { event }.to change { team.reload.uninstalled? }.from(false).to(true)
  end
end
