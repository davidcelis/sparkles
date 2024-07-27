require "rails_helper"

RSpec.describe Slack::Commands::Leaderboard do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

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
      text: "",
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

  let(:first_place) { "U02JE49NDNY" }
  let(:second_place_tie_1) { "U02A8K2B03X" }
  let(:second_place_tie_2) { "U02K7AUR7LN" }
  let(:third_place) { "U02K1HUQ60Y" }

  before do
    team.sparkles.create!(user_id: first_place, from_user_id: first_place, channel_id: "C02J565A4CE", reason: "for practicing self care", message_ts: "12345.67890", permalink: "https://example.com")
    team.sparkles.create!(user_id: first_place, from_user_id: second_place_tie_1, channel_id: "C02J565A4CE", reason: "for being awesome", message_ts: "12345.67890", permalink: "https://example.com")
    team.sparkles.create!(user_id: first_place, from_user_id: second_place_tie_2, channel_id: "C02J565A4CE", reason: "for being really awesome", message_ts: "12345.67890", permalink: "https://example.com")
    team.sparkles.create!(user_id: first_place, from_user_id: third_place, channel_id: "C02J565A4CE", message_ts: "12345.67890", permalink: "https://example.com")

    team.sparkles.create!(user_id: second_place_tie_1, from_user_id: "U02JE49NDNY", channel_id: "C02J565A4CE", reason: "for being awesome", message_ts: "12345.67890", permalink: "https://example.com")
    team.sparkles.create!(user_id: second_place_tie_1, from_user_id: "U02JE49NDNY", channel_id: "C02J565A4CE", reason: "for being awesome", message_ts: "12345.67890", permalink: "https://example.com")

    team.sparkles.create!(user_id: second_place_tie_2, from_user_id: "U02JE49NDNY", channel_id: "C02J565A4CE", reason: "for being awesome", message_ts: "12345.67890", permalink: "https://example.com")
    team.sparkles.create!(user_id: second_place_tie_2, from_user_id: "U02JE49NDNY", channel_id: "C02J565A4CE", reason: "for being awesome", message_ts: "12345.67890", permalink: "https://example.com")

    team.sparkles.create!(user_id: third_place, from_user_id: "U02JE49NDNY", channel_id: "C02J565A4CE", reason: "for being awesome", message_ts: "12345.67890", permalink: "https://example.com")
  end

  let(:expected_modal) do
    {
      type: "modal",
      title: {type: "plain_text", text: "Top Sparklers"},
      close: {type: "plain_text", text: "Close"},
      blocks: [
        {type: "section", text: {type: "mrkdwn", text: "Here’s the current leaderboard for your team! :sparkles:"}},
        {type: "divider"},
        {type: "section", fields: [{type: "mrkdwn", text: ":one: <@#{first_place}>:"}, {type: "mrkdwn", text: ":sparkle: 4 points"}]},
        {type: "section", fields: [{type: "mrkdwn", text: ":two: <@#{second_place_tie_1}>:"}, {type: "mrkdwn", text: ":sparkle: 2 points"}]},
        {type: "section", fields: [{type: "mrkdwn", text: ":two: <@#{second_place_tie_2}>:"}, {type: "mrkdwn", text: ":sparkle: 2 points"}]},
        {type: "section", fields: [{type: "mrkdwn", text: ":three: <@#{third_place}>:"}, {type: "mrkdwn", text: ":sparkle: 1 point"}]}
      ]
    }
  end

  subject(:command) { described_class.execute(params) }
  let(:result) { command }

  it "opens a modal with the leaderboard" do
    expect(result).to be_nil

    expect(modal_request).to have_been_requested
  end

  context "when there are 10 or more users" do
    before do
      15.times do |i|
        i.times { team.sparkles.create!(user_id: "U00000000#{i}", from_user_id: "U02JE49NDNY", channel_id: "C02J565A4CE", reason: "for being awesome", message_ts: "12345.67890", permalink: "https://example.com") }
      end
    end

    let(:expected_modal) do
      {
        type: "modal",
        title: {type: "plain_text", text: "Top Sparklers"},
        close: {type: "plain_text", text: "Close"},
        blocks: [
          {type: "section", text: {type: "mrkdwn", text: "Here’s the current leaderboard for your team! :sparkles:"}},
          {type: "divider"},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::one:")}, {type: "mrkdwn", text: ":sparkle: 14 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::two:")}, {type: "mrkdwn", text: ":sparkle: 13 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::three:")}, {type: "mrkdwn", text: ":sparkle: 12 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::four:")}, {type: "mrkdwn", text: ":sparkle: 11 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::five:")}, {type: "mrkdwn", text: ":sparkle: 10 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::six:")}, {type: "mrkdwn", text: ":sparkle: 9 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::seven:")}, {type: "mrkdwn", text: ":sparkle: 8 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::eight:")}, {type: "mrkdwn", text: ":sparkle: 7 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":zero::nine:")}, {type: "mrkdwn", text: ":sparkle: 6 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::zero:")}, {type: "mrkdwn", text: ":sparkle: 5 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::one:")}, {type: "mrkdwn", text: ":sparkle: 4 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::one:")}, {type: "mrkdwn", text: ":sparkle: 4 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::two:")}, {type: "mrkdwn", text: ":sparkle: 3 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::three:")}, {type: "mrkdwn", text: ":sparkle: 2 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::three:")}, {type: "mrkdwn", text: ":sparkle: 2 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::three:")}, {type: "mrkdwn", text: ":sparkle: 2 points"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::four:")}, {type: "mrkdwn", text: ":sparkle: 1 point"}]},
          {type: "section", fields: [{type: "mrkdwn", text: a_string_starting_with(":one::four:")}, {type: "mrkdwn", text: ":sparkle: 1 point"}]}
        ]
      }
    end

    it "pads the ranks with zeros" do
      expect(result).to be_nil

      expect(modal_request).to have_been_requested
    end
  end
end
