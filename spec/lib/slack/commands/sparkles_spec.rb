require "rails_helper"

RSpec.describe Slack::Commands::Sparkles do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

  let(:user_id) { "U02K1HUQ60Y" }
  let(:text) { "<@#{user_id}>" }
  let(:params) {
    {
      token: SecureRandom.base58,
      team_id: team.id,
      team_domain: "sparkles-lol",
      channel_id: "C02J565A4CE",
      channel_name: "general",
      user_id: "U02JE49NDNY",
      user_name: "davidcelis",
      command: "/sparkles",
      text: text,
      api_app_id: "A02N01LRHLP",
      is_enterprise_install: "false",
      response_url: "https://hooks.slack.com/commands/#{team.id}/respond/here",
      trigger_id: "7440325491831.2647606822032.9a375190d6d176398ffa83e1d7f15d8e"
    }
  }

  let!(:modal_request) do
    stub_request(:post, "https://slack.com/api/views.open").with { |req|
      body = Rack::Utils.parse_query(req.body)
      expect(body["trigger_id"]).to eq(params[:trigger_id])

      view = JSON.parse(body["view"]).deep_symbolize_keys
      expect(view).to match(expected_modal)
    }.to_return(status: 200, body: {ok: true}.to_json)
  end

  subject(:command) { described_class.execute(params) }
  let(:result) { command }

  context "when the user has not received any sparkles" do
    let(:expected_modal) do
      {
        type: "modal",
        title: {type: "plain_text", text: "Sparkles"},
        close: {type: "plain_text", text: "Close"},
        blocks: [
          {type: "section", text: {type: "mrkdwn", text: "<@#{user_id}> hasn’t received any sparkles yet! :cry: Maybe you can change that?"}}
        ]
      }
    end

    it "opens a modal with a message that the user has not received any sparkles" do
      expect(result).to be_nil

      expect(modal_request).to have_been_requested
    end

    context "when the user is the one requesting their own sparkles" do
      let(:params) { super().merge(user_id: user_id) }

      let(:expected_modal) do
        {
          type: "modal",
          title: {type: "plain_text", text: "Sparkles"},
          close: {type: "plain_text", text: "Close"},
          blocks: [
            {type: "section", text: {type: "mrkdwn", text: "You haven’t received any sparkles yet! :cry: Go do something nice or make someone laugh!"}}
          ]
        }
      end

      ["<@U02K1HUQ60Y>", "me"].each do |argument|
        it "opens a modal with the user's sparkles via /sparkles #{argument}" do
          expect(result).to be_nil

          expect(modal_request).to have_been_requested
        end
      end
    end
  end

  context "when the user has received sparkles" do
    let!(:sparkle_1) { team.sparkles.create!(user_id: user_id, from_user_id: "U02A8K2B03X", channel_id: "C02J565A4CE", reason: "for being awesome", message_ts: "12345.67890", permalink: "https://example.com", created_at: Time.current) }
    let!(:sparkle_2) { team.sparkles.create!(user_id: user_id, from_user_id: user_id, channel_id: "C02J565A4CE", reason: "for practicing self care", message_ts: "01234.56789", permalink: "https://sparkles.lol", created_at: 30.minutes.ago) }
    let!(:sparkle_3) { team.sparkles.create!(user_id: user_id, from_user_id: "U02K7AUR7LN", channel_id: "C02J565A4CE", reason: nil, message_ts: "12345.67890", permalink: "https://example.com", created_at: 1.hour.ago) }

    let(:expected_modal) do
      {
        type: "modal",
        title: {type: "plain_text", text: "Sparkles"},
        close: {type: "plain_text", text: "Close"},
        blocks: [
          {type: "section", text: {type: "mrkdwn", text: "Here are all the sparkles that <@#{user_id}> has received! :sparkles:"}},
          {type: "divider"},
          {type: "section", text: {type: "mrkdwn", text: ":sparkle: From <@#{sparkle_1.from_user_id}> in <##{sparkle_1.channel_id}> on <!date^#{sparkle_1.created_at.to_i}^{date_short_pretty}^https://example.com|#{sparkle_1.created_at}>"}},
          {type: "context", elements: [{type: "mrkdwn", text: sparkle_1.reason}]},
          {type: "section", text: {type: "mrkdwn", text: ":sparkle: From themselves (:wink:) in <##{sparkle_2.channel_id}> on <!date^#{sparkle_2.created_at.to_i}^{date_short_pretty}^https://sparkles.lol|#{sparkle_2.created_at}>"}},
          {type: "context", elements: [{type: "mrkdwn", text: sparkle_2.reason}]},
          {type: "section", text: {type: "mrkdwn", text: ":sparkle: From <@#{sparkle_3.from_user_id}> in <##{sparkle_3.channel_id}> on <!date^#{sparkle_3.created_at.to_i}^{date_short_pretty}^https://example.com|#{sparkle_3.created_at}>"}}
        ]
      }
    end

    it "opens a modal with the user's sparkles" do
      expect(result).to be_nil

      expect(modal_request).to have_been_requested
    end

    context "when the user is the one requesting their own sparkles" do
      let(:params) { super().merge(user_id: user_id) }
      let(:expected_modal) do
        {
          type: "modal",
          title: {type: "plain_text", text: "Sparkles"},
          close: {type: "plain_text", text: "Close"},
          blocks: [
            {type: "section", text: {type: "mrkdwn", text: "Here are all the sparkles you’ve received! :sparkles:"}},
            {type: "divider"},
            {type: "section", text: {type: "mrkdwn", text: ":sparkle: From <@#{sparkle_1.from_user_id}> in <##{sparkle_1.channel_id}> on <!date^#{sparkle_1.created_at.to_i}^{date_short_pretty}^https://example.com|#{sparkle_1.created_at}>"}},
            {type: "context", elements: [{type: "mrkdwn", text: sparkle_1.reason}]},
            {type: "section", text: {type: "mrkdwn", text: ":sparkle: From yourself (:wink:) in <##{sparkle_2.channel_id}> on <!date^#{sparkle_2.created_at.to_i}^{date_short_pretty}^https://sparkles.lol|#{sparkle_2.created_at}>"}},
            {type: "context", elements: [{type: "mrkdwn", text: sparkle_2.reason}]},
            {type: "section", text: {type: "mrkdwn", text: ":sparkle: From <@#{sparkle_3.from_user_id}> in <##{sparkle_3.channel_id}> on <!date^#{sparkle_3.created_at.to_i}^{date_short_pretty}^https://example.com|#{sparkle_3.created_at}>"}}
          ]
        }
      end

      ["<@U02K1HUQ60Y>", "me"].each do |argument|
        it "opens a modal with the user's sparkles via /sparkles #{argument}" do
          expect(result).to be_nil

          expect(modal_request).to have_been_requested
        end
      end
    end
  end

  context "when no argument is provided" do
    let(:text) { "" }

    it "executes the Leaderboard command" do
      expect(Slack::Commands::Leaderboard).to receive(:execute).with(params)

      command
    end
  end

  context "when help is requested" do
    let(:text) { "help" }

    it "responds with a help message" do
      expect(result).to eq({
        text: Slack::Commands::Sparkles::HELP_TEXT,
        response_type: :ephemeral
      })
    end
  end

  context "when the command is not formatted correctly" do
    let(:text) { "lol" }

    it "responds with the help message" do
      expect(result).to eq({
        text: Slack::Commands::Sparkles::HELP_TEXT,
        response_type: :ephemeral
      })
    end
  end
end
