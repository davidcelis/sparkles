require "rails_helper"

RSpec.describe Slack::Events::MemberJoinedChannel do
  let(:payload) { event_fixture("member_joined_channel") }
  let(:team) { create(:team, :sparkles) }
  let!(:user) { create(:user, team: team, slack_id: payload[:event][:user]) }

  subject(:event) { Slack::Events::MemberJoinedChannel.execute(slack_team_id: team.slack_id, payload: payload[:event]) }

  context "with a public channel" do
    context "when the user is a normal member" do
      it "does nothing" do
        expect { event }.not_to change { Channel.count }
      end
    end

    context "when the user is Sparklebot" do
      before { team.update!(sparklebot_id: user.slack_id) }

      it "does nothing" do
        VCR.use_cassette("member_joined_public_channel_event") do
          expect { event }.not_to change { Channel.count }
        end
      end
    end
  end

  context "with a private channel" do
    context "when the user is a normal member" do
      it "does nothing" do
        expect { event }.not_to change { Channel.count }
      end
    end

    context "when the user is Sparklebot" do
      before { team.update!(sparklebot_id: user.slack_id) }

      it "persists the channel" do
        VCR.use_cassette("member_joined_private_channel_event") do
          expect { event }.to change { Channel.count }.by(1)
        end
      end
    end
  end
end
