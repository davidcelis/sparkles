require "rails_helper"

RSpec.describe Slack::Commands::Sparkle do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

  let(:text) { "<@U02K7AUR7LN>" }
  let(:params) {
    {
      token: SecureRandom.base58,
      team_id: team.id,
      team_domain: "sparkles-lol",
      channel_id: "C02J565A4CE",
      channel_name: "general",
      user_id: "U02JE49NDNY",
      user_name: "davidcelis",
      command: "/sparkle",
      text: text,
      api_app_id: "A02N01LRHLP",
      is_enterprise_install: "false",
      response_url: "https://hooks.slack.com/commands/#{team.id}/respond/here",
      trigger_id: "7440325491831.2647606822032.9a375190d6d176398ffa83e1d7f15d8e"
    }
  }

  let!(:scheduled_message) do
    stub_request(:post, "https://slack.com/api/chat.scheduleMessage")
      .with(body: {channel: "C02J565A4CE", post_at: 1.month.from_now.to_i, text: "Test!"})
      .to_return(status: 200, body: {ok: true, channel: "C02J565A4CE", scheduled_message_id: "Q1298393284"}.to_json)
  end

  subject(:command) { described_class.execute(params) }
  let(:result) { command }

  it "enqueues a background job to give a sparkle" do
    expect {
      command
    }.to have_enqueued_job(SparkleJob).with(
      team_id: team.id,
      channel_id: params[:channel_id],
      user_id: params[:user_id],
      recipient_id: "U02K7AUR7LN",
      reason: nil,
      response_url: params[:response_url],
      scheduled_message_id: "Q1298393284"
    )
  end

  context "when multiple users are specified" do
    let(:text) { "<@U02K7AUR7LN>, <@U03A1B2C3D4> for your help!" }

    let(:common_args) do
      {
        team_id: team.id,
        channel_id: params[:channel_id],
        user_id: params[:user_id],
        reason: "for your help!",
        response_url: params[:response_url]
      }
    end

    it "enqueues a SparkleJob for each recipient" do
      expect {
        command
      }.to have_enqueued_job(SparkleJob).with(
        recipient_id: "U02K7AUR7LN",
        scheduled_message_id: "Q1298393284",
        **common_args
      ).and have_enqueued_job(SparkleJob).with(
        recipient_id: "U03A1B2C3D4",
        **common_args
      )
    end

    context "when users are separated by spaces instead of commas" do
      let(:text) { "<@U02K7AUR7LN> <@U03A1B2C3D4> for your help!" }

      it "enqueues a SparkleJob for each recipient" do
        expect {
          command
        }.to have_enqueued_job(SparkleJob).with(
          recipient_id: "U02K7AUR7LN",
          scheduled_message_id: "Q1298393284",
          **common_args
        ).and have_enqueued_job(SparkleJob).with(
          recipient_id: "U03A1B2C3D4",
          **common_args
        )
      end
    end

    context "when a mix of commas and spaces are used" do
      let(:text) { "<@U02K7AUR7LN>   , <@U03A1B2C3D4>  <@U04D5E6F7G8>    for your help!" }

      it "enqueues a SparkleJob for each recipient" do
        expect {
          command
        }.to have_enqueued_job(SparkleJob).with(
          recipient_id: "U02K7AUR7LN",
          scheduled_message_id: "Q1298393284",
          **common_args
        ).and have_enqueued_job(SparkleJob).with(
          recipient_id: "U03A1B2C3D4",
          **common_args
        ).and have_enqueued_job(SparkleJob).with(
          recipient_id: "U04D5E6F7G8",
          **common_args
        )
      end
    end
  end

  context "when help is requested" do
    let(:text) { "help" }

    it "responds with a help message" do
      expect(result).to eq({
        text: Slack::Commands::Sparkle::HELP_TEXT,
        response_type: :ephemeral
      })
    end
  end

  context "when a reason is provided" do
    let(:text) { "<@U02K7AUR7LN> for being awesome" }

    it "provides the reason to the background job" do
      expect {
        command
      }.to have_enqueued_job(SparkleJob).with(
        team_id: team.id,
        channel_id: params[:channel_id],
        user_id: params[:user_id],
        recipient_id: "U02K7AUR7LN",
        reason: "for being awesome",
        response_url: params[:response_url],
        scheduled_message_id: "Q1298393284"
      )
    end
  end

  context "when the command is not formatted correctly" do
    let(:text) { "<#C02J565A4CE> lol" }

    it "responds with an error message" do
      expect(result).to eq({
        text: "Sorry, I didn’t understand that.\n\nUsage: `/sparkle @user [@user2] [@user3...] [reason]`",
        response_type: :ephemeral
      })
    end
  end

  context "when Sparklebot is not in the channel" do
    before do
      allow_any_instance_of(Slack::Web::Client).to receive(:chat_scheduleMessage).and_raise(Slack::Web::Api::Errors::NotInChannel, "not_in_channel")
    end

    it "responds with an error message" do
      expect(result).to eq({
        text: "Oops! You'll need to `/invite` me to this channel before I can work here :sweat_smile: Here’s that sparkle you tried to give away so you can copy and paste it back!\n\n/sparkle #{text}",
        response_type: :ephemeral
      })
    end
  end

  context "when an unexpected error occurs" do
    before do
      allow_any_instance_of(Slack::Web::Client).to receive(:chat_scheduleMessage).and_raise(Slack::Web::Api::Errors::FatalError, "fatal_error")
    end

    it "responds with an error message" do
      expect(result).to eq({
        text: "Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime. Here’s that sparkle you tried to give away so you can try again more easily!\n\n/sparkle #{text}",
        response_type: :ephemeral
      })
    end
  end
end
