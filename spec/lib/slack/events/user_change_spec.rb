require "rails_helper"

RSpec.describe Slack::Events::UserChange do
  let(:payload) { event_fixture("user_change") }
  let(:team) { create(:team, :sparkles) }

  subject(:event) { Slack::Events::UserChange.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  context "when the user is a normal human" do
    let!(:user) { create(:user, team: team, slack_id: payload[:event][:user][:id]) }

    it "modifies the user" do
      expect { event }.to change {
        user.reload.name
      }.to("David Celis").and change {
        user.reload.username
      }.to("David").and change {
        user.reload.image_url
      }.to("https://secure.gravatar.com/avatar/66b085a6f16864adae78586e92811a73.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0002-512.png")
    end
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
