require "rails_helper"

RSpec.describe Slack::CommandsController, type: :request do
  let(:team) do
    Team.create!(id: "T02K1HUQ60Y", name: "Sparkles", sparklebot_id: "USPARKLEBOT", access_token: "<ACCESS_TOKEN>")
  end

  describe "POST /slack/commands" do
    before do
      allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
    end

    describe "/sparkle" do
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

      it "enqueues a background job to give a sparkle" do
        expect {
          post slack_commands_path, params: params
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

      context "when help is requested" do
        let(:text) { "help" }

        it "responds with a help message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: Slack::Commands::Sparkle::HELP_TEXT,
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when a reason is provided" do
        let(:text) { "<@U02K7AUR7LN> for being awesome" }

        it "provides the reason to the background job" do
          expect {
            post slack_commands_path, params: params
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
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: "Sorry, I didn’t understand that.\n\nUsage: `/sparkle @user [reason]`",
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when Sparklebot is not in the channel" do
        before do
          allow_any_instance_of(Slack::Web::Client).to receive(:chat_scheduleMessage).and_raise(Slack::Web::Api::Errors::NotInChannel, "not_in_channel")
        end

        it "responds with an error message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: "Oops! You'll need to `/invite` me to this channel before I can work here :sweat_smile: Here’s that sparkle you tried to give away so you can copy and paste it back!\n\n/sparkle #{text}",
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when an unexpected error occurs" do
        before do
          allow_any_instance_of(Slack::Web::Client).to receive(:chat_scheduleMessage).and_raise(Slack::Web::Api::Errors::FatalError, "fatal_error")
        end

        it "responds with an error message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: "Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime. Here’s that sparkle you tried to give away so you can try again more easily!\n\n/sparkle #{text}",
            response_type: :ephemeral
          }.to_json)
        end
      end
    end

    describe "/sparkles" do
      let(:params) do
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
      end

      let!(:modal_request) do
        stub_request(:post, "https://slack.com/api/views.open").with { |req|
          body = Rack::Utils.parse_query(req.body)
          expect(body["trigger_id"]).to eq(params[:trigger_id])

          view = JSON.parse(body["view"]).deep_symbolize_keys
          expect(view).to match(expected_modal)
        }.to_return(status: 200, body: {ok: true}.to_json)
      end

      context "when no text is provided" do
        let(:text) { "" }

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

        it "opens a modal with the leaderboard" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({response_type: :ephemeral}.to_json)

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
            post slack_commands_path, params: params

            expect(response).to have_http_status(:ok)
            expect(response.body).to eq({response_type: :ephemeral}.to_json)

            expect(modal_request).to have_been_requested
          end
        end
      end

      context "when a user is specified" do
        let(:user_id) { "U02K1HUQ60Y" }
        let(:text) { "<@#{user_id}>" }

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
            post slack_commands_path, params: params

            expect(response).to have_http_status(:ok)
            expect(response.body).to eq({response_type: :ephemeral}.to_json)

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
                post slack_commands_path, params: params

                expect(response).to have_http_status(:ok)
                expect(response.body).to eq({response_type: :ephemeral}.to_json)

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
            post slack_commands_path, params: params

            expect(response).to have_http_status(:ok)
            expect(response.body).to eq({response_type: :ephemeral}.to_json)

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
                post slack_commands_path, params: params

                expect(response).to have_http_status(:ok)
                expect(response.body).to eq({response_type: :ephemeral}.to_json)

                expect(modal_request).to have_been_requested
              end
            end
          end
        end
      end

      context "when help is requested" do
        let(:text) { "help" }

        it "responds with a help message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: Slack::Commands::Sparkles::HELP_TEXT,
            response_type: :ephemeral
          }.to_json)
        end
      end

      context "when the command is not formatted correctly" do
        let(:text) { "lol" }

        it "responds with the help message" do
          post slack_commands_path, params: params

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({
            text: Slack::Commands::Sparkles::HELP_TEXT,
            response_type: :ephemeral
          }.to_json)
        end
      end
    end
  end
end
