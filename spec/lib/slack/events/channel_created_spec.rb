require "rails_helper"

RSpec.describe Slack::Events::ChannelCreated do
  let(:payload) { event_fixture("channel_created") }
  let!(:team) { create(:team, :sparkles) }

  subject(:event) { Slack::Events::ChannelCreated.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "stores the channel locally" do
    VCR.use_cassette("channel_created_event") do
      expect { event }.to change { team.reload.channels.count }.from(0).to(1)
    end

    channel = team.channels.first
    expect(channel.slack_team_id).to eq("T02K1HUQ60Y")
    expect(channel.slack_id).to eq("C02J565A4CE")
    expect(channel.name).to eq("general")
    expect(channel).not_to be_private
    expect(channel).not_to be_shared
    expect(channel).not_to be_archived
    expect(channel).not_to be_read_only
  end
end
