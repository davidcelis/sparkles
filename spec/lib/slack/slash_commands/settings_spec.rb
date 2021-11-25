require "rails_helper"

RSpec.describe Slack::SlashCommands::Settings do
  let(:api_client) { user.team.api_client }
  let(:params) do
    {
      team_id: user.team.slack_id,
      user_id: user.slack_id,
      trigger_id: "1234567890.12345678901234567890.1234567890"
    }
  end

  before { expect_any_instance_of(Team).to receive(:api_client).and_return(api_client) }

  context "when called by a member" do
    let(:user) { create(:user) }

    let(:expected_view) do
      {
        type: :modal,
        title: {emoji: true, text: "Configure Sparkles", type: :plain_text},
        callback_id: "settings-#{user.team.slack_id}-#{user.slack_id}",
        blocks: [
          header_block,
          divider,
          user_leaderboard_block
        ],
        close: {emoji: true, text: ":x: Cancel", type: :plain_text},
        submit: {emoji: true, text: ":sparkles: Submit", type: :plain_text}
      }
    end

    context "when the member has left the leaderboard enabled" do
      it "opens a modal view with user_leaderboard_enabled checked" do
        expect(api_client).to receive(:views_open).with(trigger_id: params[:trigger_id], view: expected_view)

        Slack::SlashCommands::Settings.execute(params)
      end
    end

    context "when the member has disabled the leaderboard" do
      before { user.update!(leaderboard_enabled: false) }

      it "opens a modal view with user_leaderboard_enabled unchecked" do
        user_leaderboard_block[:accessory].delete(:initial_options)

        expect(api_client).to receive(:views_open).with(trigger_id: params[:trigger_id], view: expected_view)

        Slack::SlashCommands::Settings.execute(params)
      end
    end
  end

  context "when called by an admin" do
    let(:user) { create(:user, team_admin: true) }

    let(:expected_view) do
      {
        type: :modal,
        title: {emoji: true, text: "Configure Sparkles", type: :plain_text},
        callback_id: "settings-#{user.team.slack_id}-#{user.slack_id}",
        blocks: [
          header_block,
          divider,
          user_leaderboard_block,
          divider,
          admin_header_block,
          admin_context_block,
          feed_channel_block,
          team_leaderboard_block
        ],
        close: {emoji: true, text: ":x: Cancel", type: :plain_text},
        submit: {emoji: true, text: ":sparkles: Submit", type: :plain_text}
      }
    end

    context "when the admin has left their own leaderboard enabled" do
      it "opens a modal view with user_leaderboard_enabled checked" do
        expect(api_client).to receive(:views_open).with(trigger_id: params[:trigger_id], view: expected_view)

        Slack::SlashCommands::Settings.execute(params)
      end
    end

    context "when the admin has disabled their own leaderboard" do
      before { user.update!(leaderboard_enabled: false) }

      it "opens a modal view with leaderboard_enabled unchecked" do
        user_leaderboard_block[:accessory].delete(:initial_options)

        expect(api_client).to receive(:views_open).with(trigger_id: params[:trigger_id], view: expected_view)

        Slack::SlashCommands::Settings.execute(params)
      end
    end

    context "when the admin has not selected a feed channel" do
      it "opens a modal view with no initial feed channel selected" do
        expect(feed_channel_block[:accessory][:initial_channel]).to be_blank
        expect(api_client).to receive(:views_open).with(trigger_id: params[:trigger_id], view: expected_view)

        Slack::SlashCommands::Settings.execute(params)
      end
    end

    context "when the admin has configured a feed channel" do
      before { user.team.update!(slack_feed_channel_id: "C1234567890") }

      it "opens a modal view with leaderboard_enabled unchecked" do
        feed_channel_block[:accessory][:initial_channel] = user.team.slack_feed_channel_id

        expect(api_client).to receive(:views_open).with(trigger_id: params[:trigger_id], view: expected_view)

        Slack::SlashCommands::Settings.execute(params)
      end
    end

    context "when the admin has left the team leaderboard enabled" do
      it "opens a modal view with user_leaderboard_enabled checked" do
        expect(api_client).to receive(:views_open).with(trigger_id: params[:trigger_id], view: expected_view)

        Slack::SlashCommands::Settings.execute(params)
      end
    end

    context "when the admin has disabled the team leaderboard" do
      before { user.team.update!(leaderboard_enabled: false) }

      it "opens a modal view with leaderboard_enabled unchecked" do
        team_leaderboard_block[:accessory].delete(:initial_options)

        expect(api_client).to receive(:views_open).with(trigger_id: params[:trigger_id], view: expected_view)

        Slack::SlashCommands::Settings.execute(params)
      end
    end
  end

  # We're placing the expected block definitions here to avoid cluttering the
  # tests themselves.
  let(:divider) { {type: :divider} }
  let(:header_block) do
    {
      type: :section,
      text: {
        type: :mrkdwn,
        text: ":sparkles: Hi, <@#{user.slack_id}>! Here are some ways you can personalize your experience with Sparkles:"
      }
    }
  end
  let(:user_leaderboard_block) do
    {
      type: :section,
      text: {text: ":trophy: *Leaderboard settings*", type: :mrkdwn},
      accessory: {
        type: :checkboxes,
        action_id: :user_leaderboard_enabled,
        options: [{
          description: {
            type: :mrkdwn,
            text: "Disabling the leaderboard will hide point totals in most places, just for you! Others in your team will still see you in the leaderboard."
          },
          text: {text: "*Enable the leaderboard*", type: :mrkdwn},
          value: "true"
        }],
        initial_options: [{
          description: {
            type: :mrkdwn,
            text: "Disabling the leaderboard will hide point totals in most places, just for you! Others in your team will still see you in the leaderboard."
          },
          text: {text: "*Enable the leaderboard*", type: :mrkdwn},
          value: "true"
        }]
      }
    }
  end
  let(:admin_header_block) do
    {
      type: :section,
      text: {text: ":lock: *Admin settings*", type: :mrkdwn}
    }
  end
  let(:admin_context_block) do
    {
      type: :context,
      elements: [{
        type: :mrkdwn,
        text: "These settings will adjust the experience for everybody on your team."
      }]
    }
  end
  let(:feed_channel_block) do
    {
      type: :section,
      text: {
        type: :mrkdwn,
        text: ":sparkle: *Sparkle Feed Channel*\nShare all sparkles as they're given!"
      },
      accessory: {
        type: :channels_select,
        action_id: :team_sparkle_feed_channel,
        placeholder: {emoji: true, text: "Channel", type: :plain_text}
      }
    }
  end
  let(:team_leaderboard_block) do
    {
      type: :section,
      text: {text: ":trophy: *Leaderboard settings*", type: :mrkdwn},
      accessory: {
        type: :checkboxes,
        action_id: :team_leaderboard_enabled,
        initial_options: [{
          text: {text: "*Enable the leaderboard*", type: :mrkdwn},
          description: {
            type: :mrkdwn,
            text: "Disabling the leaderboard will hide all sparkle point totals, with sparkles still visible via a team directory."
          },
          value: "true"
        }],
        options: [{
          text: {text: "*Enable the leaderboard*", type: :mrkdwn},
          description: {
            type: :mrkdwn,
            text: "Disabling the leaderboard will hide all sparkle point totals, with sparkles still visible via a team directory."
          },
          value: "true"
        }]
      }
    }
  end
end
