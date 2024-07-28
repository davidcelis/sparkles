require "rails_helper"

RSpec.describe SparkleJob, type: :job do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

  let(:api_client) { instance_double(Slack::Web::Client) }
  let(:users_info_response) do
    double(user: double(id: options[:recipient_id], deleted: false, is_bot: false))
  end

  before do
    allow(Team).to receive(:find).with(team.id).and_return(team)
    allow(team).to receive(:api_client).and_return(api_client)

    allow(api_client).to receive(:users_info)
      .with(user: options[:recipient_id])
      .and_return(users_info_response)
  end

  shared_examples "a recipient that has been deactivated" do
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

  shared_examples "a recipient that is a bot" do
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

  shared_examples "a recipient that can't be found" do
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

  context "when the sparkle is being given via the /sparkle command" do
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

    let(:message_ts) { "01234.56789" }
    let(:permalink_response) do
      double(permalink: "https://sparkles-lol.slack.com/archives/#{options[:channel_id]}/p1234567890")
    end

    before do
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
        text: ":tada: <@U02K7AUR7LN> just got their first :sparkle:! :tada:",
        thread_ts: nil
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
          text: ":tada: <@U02K7AUR7LN> just got their first :sparkle:! :tada:",
          thread_ts: nil
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
          text: a_string_ending_with("<@U02K7AUR7LN> now has 2 sparkles :sparkles:"),
          thread_ts: nil
        ).and_return(double(ts: message_ts))

        expect {
          SparkleJob.perform_now(options)
        }.to change {
          team.sparkles.count
        }.by(1)
      end
    end

    context "when the recipient is giving themselves a sparkle" do
      let(:options) { super().merge(recipient_id: "U02JE49NDNY") }

      it "responds with a message encouraging the recipient" do
        expect(api_client).to receive(:chat_postMessage).with(
          channel: options[:channel_id],
          text: a_string_ending_with("Nothing wrong with a little pat on the back, eh <@U02JE49NDNY>?"),
          thread_ts: nil
        ).and_return(double(ts: message_ts))

        expect {
          SparkleJob.perform_now(options)
        }.to change {
          team.sparkles.count
        }.by(1)
      end
    end

    context "when an unexpected error occurs" do
      before do
        allow(api_client).to receive(:chat_postMessage).and_raise(Slack::Web::Api::Errors::FatalError, "fatal_error")
      end

      it "reports the error" do
        expect(Sentry).to receive(:capture_exception).with(an_instance_of(Slack::Web::Api::Errors::FatalError))

        text = "Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime. Here’s that sparkle you tried to give away so you can try again more easily!\n\n/sparkle <@#{options[:recipient_id]}> #{options[:reason]}"

        expect(Faraday).to receive(:post).with(
          options[:response_url],
          {text: text}.to_json,
          "Content-Type" => "application/json"
        )

        SparkleJob.perform_now(options)
      end
    end

    it_behaves_like "a recipient that has been deactivated"
    it_behaves_like "a recipient that is a bot"
    it_behaves_like "a recipient that can't be found"
  end

  context "when the sparkle is being given via a reaction" do
    let(:options) do
      {
        team_id: team.id,
        user_id: "U02JE49NDNY",
        recipient_id: "U02K7AUR7LN",
        channel_id: "C02NCMN16PQ",
        reaction_to_ts: "1722179966.261999"
      }
    end

    let(:reaction_permalink_response) do
      double(permalink: "https://sparkles-lol.slack.com/archives/#{options[:channel_id]}/p1722179966.261999")
    end

    let(:message_ts) { "01234.56789" }
    let(:permalink_response) do
      double(permalink: "https://sparkles-lol.slack.com/archives/#{options[:channel_id]}/p01234.56789")
    end

    before do
      allow(api_client).to receive(:chat_getPermalink)
        .with(channel: options[:channel_id], message_ts: options[:reaction_to_ts])
        .and_return(reaction_permalink_response)

      allow(api_client).to receive(:chat_getPermalink)
        .with(channel: options[:channel_id], message_ts: message_ts)
        .and_return(permalink_response)
    end

    it "gives the recipient a sparkle" do
      expect(api_client).to receive(:chat_postMessage).with(
        channel: options[:channel_id],
        text: ":tada: <@#{options[:recipient_id]}> just got their first :sparkle:! :tada:",
        thread_ts: options[:reaction_to_ts]
      ).and_return(double(ts: message_ts))

      expect {
        SparkleJob.perform_now(options)
      }.to change {
        team.sparkles.count
      }.by(1)

      sparkle = team.sparkles.last
      expect(sparkle.user_id).to eq(options[:recipient_id])
      expect(sparkle.from_user_id).to eq(options[:user_id])
      expect(sparkle.channel_id).to eq(options[:channel_id])
      expect(sparkle.reason).to eq("because I approve <#{reaction_permalink_response.permalink}|this message>!")
      expect(sparkle.message_ts).to eq(message_ts)
      expect(sparkle.reaction_to_ts).to eq(options[:reaction_to_ts])
      expect(sparkle.permalink).to eq(permalink_response.permalink)
    end

    context "when the original message is in a thread" do
      let(:reaction_permalink_response) do
        double(permalink: "https://sparkles-lol.slack.com/archives/#{options[:channel_id]}/p1722179966.261999?thread_ts=1234567890.97531")
      end

      it "posts the response as a threaded reply to the original message" do
        expect(api_client).to receive(:chat_postMessage).with(
          channel: options[:channel_id],
          text: ":tada: <@#{options[:recipient_id]}> just got their first :sparkle:! :tada:",
          thread_ts: "1234567890.97531"
        ).and_return(double(ts: message_ts))

        SparkleJob.perform_now(options)

        sparkle = team.sparkles.last
        expect(sparkle.message_ts).to eq(message_ts)
        expect(sparkle.permalink).to eq(permalink_response.permalink)
      end
    end

    context "when the user had already reacted to the message previously" do
      let!(:existing_sparkle) do
        team.sparkles.create!(
          user_id: options[:recipient_id],
          from_user_id: options[:user_id],
          channel_id: options[:channel_id],
          reaction_to_ts: options[:reaction_to_ts],
          reason: "because I approve <https://sparkles-lol.slack.com/archives/C02NCMN16PQ/p1722179966.261999|this message>!",
          message_ts: "12345.67890",
          permalink: "https://sparkles-lol.slack.com/archives/C02NCMN16PQ/p1234567890"
        )
      end

      it "does not create a new sparkle" do
        expect {
          SparkleJob.perform_now(options)
        }.not_to change {
          team.sparkles.count
        }
      end
    end

    context "when another user has already reacted to the message" do
      let!(:existing_sparkle) do
        team.sparkles.create!(
          user_id: options[:recipient_id],
          from_user_id: options[:recipient_id],
          channel_id: options[:channel_id],
          reaction_to_ts: options[:reaction_to_ts],
          reason: "because I approve <https://sparkles-lol.slack.com/archives/C02NCMN16PQ/p1722179966.261999|this message>!",
          message_ts: message_ts,
          permalink: "https://sparkles-lol.slack.com/archives/C02NCMN16PQ/p1234567890"
        )
      end

      it "updates the existing response message with the latest count" do
        expect(api_client).to receive(:chat_update).with(
          channel: options[:channel_id],
          ts: existing_sparkle.message_ts,
          text: a_string_ending_with("<@#{options[:recipient_id]}> now has 2 sparkles :sparkles:\n\nNothing wrong with a little pat on the back, eh <@#{options[:recipient_id]}>?"),
          as_user: true
        )

        expect {
          SparkleJob.perform_now(options)
        }.to change {
          team.sparkles.count
        }.by(1)

        sparkle = team.sparkles.last
        expect(sparkle.message_ts).to eq(existing_sparkle.message_ts)
        expect(sparkle.permalink).to eq(existing_sparkle.permalink)
      end
    end

    context "when the recipient has already received a sparkle" do
      let!(:sparkle) do
        team.sparkles.create!(
          user_id: options[:recipient_id],
          from_user_id: options[:user_id],
          channel_id: options[:channel_id],
          reason: "for being awesome!",
          message_ts: "12345.67890",
          permalink: "https://sparkles-lol.slack.com/archives/C02J565A4CE/p1234567890"
        )
      end

      it "announces the number of sparkles the recipient now has" do
        expect(api_client).to receive(:chat_postMessage).with(
          channel: options[:channel_id],
          text: a_string_ending_with("<@U02K7AUR7LN> now has 2 sparkles :sparkles:"),
          thread_ts: options[:reaction_to_ts]
        ).and_return(double(ts: message_ts))

        expect {
          SparkleJob.perform_now(options)
        }.to change {
          team.sparkles.count
        }.by(1)
      end
    end

    context "when the recipient is giving themselves a sparkle" do
      let(:options) { super().merge(recipient_id: "U02JE49NDNY") }

      it "responds with a message encouraging the recipient" do
        expect(api_client).to receive(:chat_postMessage).with(
          channel: options[:channel_id],
          text: a_string_ending_with("Nothing wrong with a little pat on the back, eh <@U02JE49NDNY>?"),
          thread_ts: options[:reaction_to_ts]
        ).and_return(double(ts: message_ts))

        expect {
          SparkleJob.perform_now(options)
        }.to change {
          team.sparkles.count
        }.by(1)
      end
    end

    context "when an unexpected error occurs" do
      before do
        allow(api_client).to receive(:chat_postMessage).and_raise(Slack::Web::Api::Errors::FatalError, "fatal_error")
      end

      it "reports the error" do
        expect(Sentry).to receive(:capture_exception).with(an_instance_of(Slack::Web::Api::Errors::FatalError))

        expect(api_client).to receive(:chat_postEphemeral).with(
          channel: options[:channel_id],
          user: options[:user_id],
          text: "Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime."
        )

        SparkleJob.perform_now(options)
      end
    end

    it_behaves_like "a recipient that has been deactivated"
    it_behaves_like "a recipient that is a bot"
    it_behaves_like "a recipient that can't be found"
  end
end
