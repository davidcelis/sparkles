require "rails_helper"

RSpec.describe SparkleWorker do
  let(:team) { create(:team, :sparkles, slack_feed_channel_id: nil) }
  let(:channel) { create(:channel, team: team, slack_id: "C02NCMN16PQ") }
  let(:sparkler) { create(:user, team: team, slack_id: "U02JE49NDNY") }
  let(:sparklee) { create(:user, team: team, slack_id: "U02JZCB1U5D") }
  let(:reason) { "for always being there for me" }

  # We unfortunately need to do this for our API call expectations
  let(:api_client) { team.api_client }
  before { allow_any_instance_of(Team).to receive(:api_client).and_return(api_client) }

  let(:options) do
    {
      slack_team_id: team.slack_id,
      slack_channel_id: channel.slack_id,
      slack_sparkler_id: sparkler.slack_id,
      slack_sparklee_id: sparklee.slack_id,
      reason: reason
    }
  end

  subject(:worker) { SparkleWorker.new.perform(options) }

  it "can award a user their first sparkle" do
    expect(team.api_client).to receive(:chat_postMessage).with(
      channel: channel.slack_id,
      text: ":tada: <@#{sparklee.slack_id}> just got their first :sparkle:! :tada:"
    ).and_call_original

    VCR.use_cassette("sparkle_user_first_time") do
      expect { worker }.to change { Sparkle.count }.by(1)
    end

    sparkle = sparklee.sparkles.last
    expect(sparkle.sparkler).to eq(sparkler)
    expect(sparkle.channel).to eq(channel)
    expect(sparkle.reason).to eq(reason)
    expect(sparkle.permalink).to eq("https://sparkles-ts66289.slack.com/archives/C02NCMN16PQ/p1637801189001300")
  end

  context "when the team has configured a slack feed channel" do
    let(:feed_channel) { create(:channel, team: team, slack_id: "C02LEQ0E1QS") }
    before { team.update!(slack_feed_channel_id: feed_channel.slack_id) }

    it "cross-posts the sparkle to the feed channel" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: ":tada: <@#{sparklee.slack_id}> just got their first :sparkle:! :tada:"
      ).and_call_original

      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: feed_channel.slack_id,
        text: ":sparkle: Somebody just got a <https://sparkles-ts66289.slack.com/archives/C02NCMN16PQ/p1637801189001300|sparkle>!"
      ).and_call_original

      VCR.use_cassette("sparkle_user_feed_channel") do
        expect { worker }.to change { Sparkle.count }.by(1)
      end
    end
  end

  context "when the recipient has already received at least one sparkle" do
    before { create_list(:sparkle, 2, team: team, sparklee: sparklee, sparkler: sparkler, channel: channel) }

    it "announces the number of sparkles" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: a_string_including("<@#{sparklee.slack_id}> now has 3 sparkles :sparkles:")
      ).and_call_original

      VCR.use_cassette("sparkle_user") do
        expect { worker }.to change { Sparkle.count }.by(1)
      end
    end
  end

  context "when the recipient has disabled their leaderboard" do
    before { sparklee.update!(leaderboard_enabled: false) }

    it "does not announce the number of sparkles" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: a_string_including("<@#{sparklee.slack_id}> just got a :sparkle:!")
      ).and_call_original

      VCR.use_cassette("sparkle_user_leaderboard_disabled") do
        expect { worker }.to change { Sparkle.count }.by(1)
      end
    end
  end

  context "when the team leaderboard is disabled" do
    before { team.update!(leaderboard_enabled: false) }

    it "does not announce the number of sparkles" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: a_string_including("<@#{sparklee.slack_id}> just got a :sparkle:!")
      ).and_call_original

      VCR.use_cassette("sparkle_user_team_leaderboard_disabled") do
        expect { worker }.to change { Sparkle.count }.by(1)
      end
    end
  end

  context "when someone gives themselves a sparkle" do
    let(:sparklee) { sparkler }

    it "says theres nothing wrong with a pat on the back :)" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: a_string_including("Nothing wrong with a little pat on the back, eh <@#{sparklee.slack_id}>?")
      ).and_call_original

      VCR.use_cassette("sparkle_user_pat_on_the_back") do
        expect { worker }.to change { Sparkle.count }.by(1)
      end
    end
  end

  context "when someone tries to give a sparkle to a guest user" do
    it "posts an error message" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: "Oops, I don't work with guest users or in shared channels right now :sweat: Sorry about that!"
      )

      VCR.use_cassette("sparkle_user_guest") do
        expect { worker }.not_to change { Sparkle.count }
      end
    end
  end

  context "when someone tries to give a sparkle to Sparklebot" do
    before { options[:slack_sparklee_id] = team.sparklebot_id }

    it "posts an error message" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: "Aww, thank you, <@#{sparkler.slack_id}>! That's so thoughtful, but I'm already swimming in sparkles! I couldn't possibly take one of yours, but I apprecate the gesture nonetheless :sparkles:"
      )

      VCR.use_cassette("sparkle_user_sparklebot") do
        expect { worker }.not_to change { Sparkle.count }
      end
    end
  end

  context "when someone tries to give a sparkle to Slackbot" do
    before { options[:slack_sparklee_id] = "USLACKBOT" }

    it "posts an error message" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: "It's so nice that you want to recognize one of my fellow bots! They've all politely declined to join the fun of sparkle hoarding, but I'll pass along your thanks."
      )

      VCR.use_cassette("sparkle_user_slackbot") do
        expect { worker }.not_to change { Sparkle.count }
      end
    end
  end

  context "when someone tries to give a sparkle to a generic bot" do
    before { options[:slack_sparklee_id] = "U02J7PC3Z39" }

    it "posts an error message" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: "It's so nice that you want to recognize one of my fellow bots! They've all politely declined to join the fun of sparkle hoarding, but I'll pass along your thanks."
      )

      VCR.use_cassette("sparkle_user_bot") do
        expect { worker }.not_to change { Sparkle.count }
      end
    end
  end

  context "when someone tries to spoof a user ID" do
    before { options[:slack_sparklee_id] = "U1234567890" }

    it "posts an error message" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: "I couldn't find the teammate you're trying to sparkle :sweat: Make sure you're using a highlighted @mention and that they aren't a guest member!"
      )

      VCR.use_cassette("sparkle_user_doesnt_exist") do
        expect { worker }.not_to change { Sparkle.count }
      end
    end
  end

  context "when any generic error occurs" do
    it "posts an error message and retries with the retried flag set to true" do
      expect(team.api_client).to receive(:chat_postMessage).with(
        channel: channel.slack_id,
        text: "Oops, I ran into a problem in the Sparkle pipeline :sweat: I'll notify my mechanic about this and keep trying for a bit in the meantime. Sorry!"
      )

      expect(SparkleWorker).to receive(:perform_async).with(options.merge(retried: true))

      VCR.use_cassette("sparkle_user_error") do
        expect { worker }.not_to change { Sparkle.count }
      end
    end

    context "when already retried" do
      before { options[:retried] = true }

      it "does not re-post the error message and re-raises to trigger the default retry mechanism" do
        allow(team.api_client).to receive(:users_info).and_raise(RuntimeError.new)
        expect(team.api_client).not_to receive(:chat_postMessage)
        expect(SparkleWorker).not_to receive(:perform_async)

        expect { worker }.to raise_error(RuntimeError)
      end
    end
  end
end
