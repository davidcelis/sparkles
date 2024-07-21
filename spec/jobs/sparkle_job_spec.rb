require "rails_helper"

RSpec.describe SparkleJob, type: :job do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end
  let(:api_client) { instance_double(Slack::Web::Client) }

  let(:options) do
    {
      team_id: team.id,
      channel_id: "C02J565A4CE",
      user_id: "U02JE49NDNY",
      recipient_id: "U02K7AUR7LN",
      reason: nil,
      response_url: "https://hooks.slack.com/commands/#{team.id}/respond/here",
      scheduled_message_id: "Q1298393284"
    }
  end

  let(:users_info_response) do
    double(user: double(id: options[:recipient_id], deleted: false, is_bot: false))
  end

  let(:message_ts) { "01234.56789" }
  let(:permalink_response) do
    double(permalink: "https://sparkles-lol.slack.com/archives/#{options[:channel_id]}/p1234567890")
  end

  before do
    allow(Team).to receive(:find).with(team.id).and_return(team)
    allow(team).to receive(:api_client).and_return(api_client)

    allow(api_client).to receive(:users_info)
      .with(user: options[:recipient_id])
      .and_return(users_info_response)

    allow(api_client).to receive(:chat_getPermalink)
      .with(channel: options[:channel_id], message_ts: message_ts)
      .and_return(permalink_response)

    # This has to happen regardless of whether or not the sparkle succeeds, so
    # we'll make it a global expectation to ensure it's always called.
    expect(api_client).to receive(:chat_deleteScheduledMessage).with(
      channel: options[:channel_id],
      scheduled_message_id: options[:scheduled_message_id]
    )
  end

  it "gives the recipient a sparkle" do
    expect(api_client).to receive(:chat_postMessage).with(
      channel: options[:channel_id],
      text: ":tada: <@U02K7AUR7LN> just got their first :sparkle:! :tada:"
    ).and_return(double(ts: message_ts))

    expect {
      SparkleJob.perform_now(options)
    }.to change {
      team.sparkles.count
    }.by(1)

    sparkle = team.sparkles.last
    expect(sparkle.user_id).to eq("U02K7AUR7LN")
    expect(sparkle.from_user_id).to eq("U02JE49NDNY")
    expect(sparkle.channel_id).to eq("C02J565A4CE")
    expect(sparkle.reason).to be_nil
    expect(sparkle.message_ts).to eq(message_ts)
    expect(sparkle.permalink).to eq("https://sparkles-lol.slack.com/archives/C02J565A4CE/p1234567890")
  end

  context "when a reason is provided" do
    let(:options) { super().merge(reason: "for being awesome!") }

    it "gives the recipient a sparkle with the reason" do
      expect(api_client).to receive(:chat_postMessage).with(
        channel: options[:channel_id],
        text: ":tada: <@U02K7AUR7LN> just got their first :sparkle:! :tada:"
      ).and_return(double(ts: message_ts))

      expect {
        SparkleJob.perform_now(options)
      }.to change {
        team.sparkles.count
      }.by(1)

      sparkle = team.sparkles.last
      expect(sparkle.reason).to eq(options[:reason])
    end
  end

  context "when the recipient has already received a sparkle" do
    let!(:sparkle) do
      team.sparkles.create!(
        user_id: "U02K7AUR7LN",
        from_user_id: "U02JE49NDNY",
        channel_id: "C02J565A4CE",
        reason: "for being awesome!",
        message_ts: "12345.67890",
        permalink: "https://sparkles-lol.slack.com/archives/C02J565A4CE/p1234567890"
      )
    end

    it "announces the number of sparkles the recipient now has" do
      expect(api_client).to receive(:chat_postMessage).with(
        channel: options[:channel_id],
        text: a_string_ending_with("<@U02K7AUR7LN> now has 2 sparkles :sparkles:")
      ).and_return(double(ts: message_ts))

      expect {
        SparkleJob.perform_now(options)
      }.to change {
        team.sparkles.count
      }.by(1)
    end
  end

  context "when the recipient has been deactivated" do
    let(:users_info_response) do
      double(user: double(deleted: true))
    end

    it "responds with an error message" do
      expect(api_client).to receive(:chat_postMessage).with(
        channel: options[:channel_id],
        text: "Oops, I can’t find that person anymore :sweat: They’ve either left the team or been deactivated. Sorry!"
      )

      SparkleJob.perform_now(options)
    end
  end

  context "when the recipient is a bot" do
    let(:users_info_response) do
      double(user: double(id: "U1029384756", deleted: false, is_bot: true))
    end

    it "responds with an error message" do
      expect(api_client).to receive(:chat_postMessage).with(
        channel: options[:channel_id],
        text: "It’s so nice that you want to recognize one of my fellow bots! They’ve all politely declined to join the fun of hoarding sparkles, but I’ll pass along your thanks."
      )

      SparkleJob.perform_now(options)
    end

    context "when the recipient is Sparklebot" do
      let(:users_info_response) do
        double(user: double(id: team.sparklebot_id, deleted: false, is_bot: true))
      end

      it "responds with an error message" do
        expect(api_client).to receive(:chat_postMessage).with(
          channel: options[:channel_id],
          text: "Aww, thank you, <@U02JE49NDNY>! That’s so thoughtful, but I’m already swimming in sparkles! I couldn’t possibly take one of yours, but I apprecate the gesture nonetheless :sparkles:"
        )

        SparkleJob.perform_now(options)
      end
    end
  end

  context "when the user can't be found" do
    before do
      allow(api_client).to receive(:users_info).and_raise(Slack::Web::Api::Errors::UserNotFound, "user_not_found")
    end

    it "responds with an error message" do
      expect(api_client).to receive(:chat_postMessage).with(
        channel: options[:channel_id],
        text: "I couldn’t find the person you’re trying to sparkle :sweat: Make sure you’re using a highlighted @mention!"
      )

      SparkleJob.perform_now(options)
    end
  end

  context "when an unexpected error occurs" do
    before do
      allow(api_client).to receive(:chat_postMessage).and_raise(Slack::Web::Api::Errors::FatalError, "fatal_error")
    end

    it "reports the error" do
      expect(Sentry).to receive(:capture_exception).with(an_instance_of(Slack::Web::Api::Errors::FatalError))

      text = <<~TEXT.strip
        Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime. Here’s that sparkle you tried to give away so you can try again more easily!

        /sparkle <@#{options[:recipient_id]}> #{options[:reason]}
      TEXT

      expect(Faraday).to receive(:post).with(
        options[:response_url],
        {text: text}.to_json,
        "Content-Type" => "application/json"
      )

      SparkleJob.perform_now(options)
    end
  end
end
