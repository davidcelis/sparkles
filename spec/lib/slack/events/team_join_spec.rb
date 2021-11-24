require "rails_helper"

RSpec.describe Slack::Events::TeamJoin do
  let(:payload) { event_fixture("team_join") }
  let!(:team) { create(:team, :sparkles) }

  subject(:event) { Slack::Events::TeamJoin.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  it "persists the user" do
    expect { event }.to change { team.users.count }.by(1)

    user = team.users.last
    expect(user.slack_id).to eq("U02KG93ESUU")
    expect(user.name).to eq("Henry")
    expect(user.username).to eq("Henry")
    expect(user.image_url).to eq("https://secure.gravatar.com/avatar/585d522c09befbdd580558c7a4e3aa5f.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0024-512.png")
    expect(user).not_to be_deactivated
    expect(user).not_to be_team_admin
  end

  context "when the user is a bot" do
    before { payload[:event][:user][:is_bot] = true }

    it "does nothing" do
      expect { event }.not_to change { team.users.count }
    end
  end

  context "when the user is restricted" do
    before { payload[:event][:user][:is_restricted] = true }

    it "does nothing" do
      expect { event }.not_to change { team.users.count }
    end
  end

  context "when the user's team_id does not match" do
    before { payload[:event][:user][:team_id] = "E163Q94DX" }

    it "does nothing" do
      expect { event }.not_to change { team.users.count }
    end
  end
end
