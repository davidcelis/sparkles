require "rails_helper"

RSpec.describe Slack::User do
  let(:response) { request_fixture("users_info") }

  describe ".from_api_response" do
    it "initializes a user from an API response" do
      user = Slack::User.from_api_response(response[:user])

      expect(user.slack_team_id).to eq("T02K1HUQ60Y")
      expect(user.slack_id).to eq("U02JZCB1U5D")
      expect(user.name).to eq("Annabelle")
      expect(user.username).to eq("Annabelle")
      expect(user.image_url).to eq("https://avatars.slack-edge.com/2021-11-06/2707404193729_7212dcae5c442f069a1f_512.jpg")
      expect(user).not_to be_deactivated
      expect(user).not_to be_bot
      expect(user).not_to be_restricted
      expect(user).not_to be_team_admin
    end
  end

  describe "#attributes" do
    let(:user) { Slack::User.from_api_response(response[:user]) }

    it "returns a hash of translated attributes suitable for local storage" do
      expect(user.attributes).to eq({
        slack_team_id: "T02K1HUQ60Y",
        slack_id: "U02JZCB1U5D",
        name: "Annabelle",
        username: "Annabelle",
        image_url: "https://avatars.slack-edge.com/2021-11-06/2707404193729_7212dcae5c442f069a1f_512.jpg",
        deactivated: false,
        team_admin: false
      })
    end
  end

  describe "#sparklebot?" do
    let(:user) { Slack::User.from_api_response(response[:user]) }
    subject { user.sparklebot? }

    context "with Sparklebot" do
      let(:response) { request_fixture("users_info_sparklebot") }

      it { is_expected.to be_truthy }
    end

    context "with a normal user" do
      let(:response) { request_fixture("users_info") }

      it { is_expected.to be_falsy }
    end

    context "with a team admin" do
      let(:response) { request_fixture("users_info_admin") }

      it { is_expected.to be_falsy }
    end

    context "with Slackbot" do
      let(:response) { request_fixture("users_info_slackbot") }

      it { is_expected.to be_falsy }
    end

    context "with a generic bot" do
      let(:response) { request_fixture("users_info_bot") }

      it { is_expected.to be_falsy }
    end
  end

  describe "#human_teammate?" do
    let(:user) { Slack::User.from_api_response(response[:user]) }
    subject { user.human_teammate? }

    context "with a normal user" do
      let(:response) { request_fixture("users_info") }

      it { is_expected.to be_truthy }
    end

    context "with a team admin" do
      let(:response) { request_fixture("users_info_admin") }

      it { is_expected.to be_truthy }
    end

    context "with a restricted user" do
      let(:response) { request_fixture("users_info_restricted") }

      it { is_expected.to be_falsy }
    end

    context "with Slackbot" do
      let(:response) { request_fixture("users_info_slackbot") }

      it { is_expected.to be_falsy }
    end

    context "with Sparklebot" do
      let(:response) { request_fixture("users_info_sparklebot") }

      it { is_expected.to be_falsy }
    end

    context "with a generic bot" do
      let(:response) { request_fixture("users_info_bot") }

      it { is_expected.to be_falsy }
    end
  end
end
