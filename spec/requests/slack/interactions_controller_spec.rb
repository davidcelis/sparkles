require "rails_helper"

RSpec.describe Slack::InteractionsController, type: :request do
  describe "POST /slack/interactions/" do
    before { allow_any_instance_of(Slack::Events::Request).to receive(:verify!) }

    let(:params) { {payload: payload.to_json} }
    let(:team) { user.team }

    context "as a user" do
      let!(:user) { create(:user, :davidcelis, team_admin: false) }

      context "enabling their leaderboard" do
        let(:payload) { interaction_fixture(:user_enable_leaderboard) }

        it "enables the user's leaderboard" do
          user.update!(leaderboard_enabled: false)

          expect {
            post slack_interactions_path, params: params
          }.to change {
            user.reload.leaderboard_enabled?
          }.from(false).to(true)
        end

        it "does nothing if already enabled" do
          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            user.reload.leaderboard_enabled?
          }
        end
      end

      context "disabling their leaderboard" do
        let(:payload) { interaction_fixture(:user_disable_leaderboard) }

        it "disables the user's leaderboard" do
          expect {
            post slack_interactions_path, params: params
          }.to change {
            user.reload.leaderboard_enabled?
          }.from(true).to(false)
        end

        it "does nothing if already disabled" do
          user.update!(leaderboard_enabled: false)

          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            user.reload.leaderboard_enabled?
          }
        end
      end

      context "with a pre-submission block action" do
        let(:payload) { interaction_fixture(:user_block_actions) }

        it "does nothing" do
          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            user.reload
          }
        end
      end
    end

    context "as an admin" do
      let!(:user) { create(:user, :davidcelis) }

      context "enabling their leaderboard" do
        let(:payload) { interaction_fixture(:admin_enable_leaderboard) }

        it "enables the admin's leaderboard" do
          user.update!(leaderboard_enabled: false)

          expect {
            post slack_interactions_path, params: params
          }.to change {
            user.reload.leaderboard_enabled?
          }.from(false).to(true)
        end

        it "does nothing if already enabled" do
          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            user.reload.leaderboard_enabled?
          }
        end
      end

      context "disabling their leaderboard" do
        let(:payload) { interaction_fixture(:admin_disable_leaderboard) }

        it "disables the admin's leaderboard" do
          expect {
            post slack_interactions_path, params: params
          }.to change {
            user.reload.leaderboard_enabled?
          }.from(true).to(false)
        end

        it "does nothing if already disabled" do
          user.update!(leaderboard_enabled: false)

          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            user.reload.leaderboard_enabled?
          }
        end
      end

      context "setting a feed channel" do
        let(:payload) { interaction_fixture(:admin_set_feed_channel) }

        it "sets the team's feed channel" do
          team.update!(slack_feed_channel_id: "C0123456789")

          expect {
            post slack_interactions_path, params: params
          }.to change {
            team.reload.slack_feed_channel_id
          }.from("C0123456789").to("C02LEQ0E1QS")
        end

        it "does nothing if already set to the same channel" do
          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            team.reload.slack_feed_channel_id
          }
        end
      end

      # TODO: Implement some way for admins to clear the `slack_feed_channel_id`

      context "enabling the team leaderboard" do
        let(:payload) { interaction_fixture(:admin_enable_team_leaderboard) }

        it "enables the team leaderboard" do
          team.update!(leaderboard_enabled: false)

          expect {
            post slack_interactions_path, params: params
          }.to change {
            team.reload.leaderboard_enabled?
          }.from(false).to(true)
        end

        it "does nothing if already enabled" do
          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            team.reload.leaderboard_enabled?
          }
        end
      end

      context "disabling the team leaderboard" do
        let(:payload) { interaction_fixture(:admin_disable_team_leaderboard) }

        it "disables the team leaderboard" do
          expect {
            post slack_interactions_path, params: params
          }.to change {
            team.reload.leaderboard_enabled?
          }.from(true).to(false)
        end

        it "does nothing if already disabled" do
          team.update!(leaderboard_enabled: false)

          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            team.reload.leaderboard_enabled?
          }
        end
      end

      context "enabling settings en masse" do
        let(:payload) { interaction_fixture(:admin_enable_all) }

        it "enables all settings" do
          user.update!(leaderboard_enabled: false)
          team.update!(leaderboard_enabled: false, slack_feed_channel_id: nil)

          expect {
            post slack_interactions_path, params: params
          }.to change {
            user.reload.leaderboard_enabled?
          }.from(false).to(true).and change {
            team.reload.leaderboard_enabled?
          }.from(false).to(true).and change {
            team.reload.slack_feed_channel_id
          }.from(nil).to("C02LEQ0E1QS")
        end

        it "does nothing to settings already enabled" do
          user.update!(leaderboard_enabled: false)
          team.update!(slack_feed_channel_id: nil)

          post slack_interactions_path, params: params
          expect(user.reload).to be_leaderboard_enabled

          team.reload
          expect(team).to be_leaderboard_enabled
          expect(team.slack_feed_channel_id).to eq("C02LEQ0E1QS")
        end
      end

      context "disabling settings en masse" do
        let(:payload) { interaction_fixture(:admin_disable_all) }

        it "disables all settings" do
          expect {
            post slack_interactions_path, params: params
          }.to change {
            user.reload.leaderboard_enabled?
          }.from(true).to(false).and change {
            team.reload.leaderboard_enabled?
          }.from(true).to(false)
        end

        it "does nothing to settings already disabled" do
          team.update!(leaderboard_enabled: false)

          post slack_interactions_path, params: params
          expect(user.reload).not_to be_leaderboard_enabled

          team.reload
          expect(team).not_to be_leaderboard_enabled
          expect(team.slack_feed_channel_id).to eq("C02LEQ0E1QS")
        end
      end

      context "with a pre-submission block action" do
        let(:payload) { interaction_fixture(:admin_block_actions) }

        it "does nothing" do
          expect {
            post slack_interactions_path, params: params
          }.not_to change {
            user.reload
          }
        end
      end
    end

    context "when slack verification fails" do
      before do
        allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
          .and_raise(Slack::Events::Request::InvalidSignature)
      end

      it "is a bad request" do
        post slack_interactions_path

        expect(response.status).to eq(400)
      end
    end
  end
end
