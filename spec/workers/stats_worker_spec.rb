require "rails_helper"

RSpec.describe StatsWorker do
  let(:team) { create(:team, :sparkles) }
  let(:channel) { create(:channel, team: team, slack_id: "C02NCMN16PQ") }
  let(:user) { create(:user, team: team, slack_id: "U02JE49NDNY", with_sparkles: 11) }
  let(:teammate) { create(:user, team: team, slack_id: "U02JZCB1U5D", with_sparkles: 1) }

  # We unfortunately need to do this for our API call expectations
  let(:api_client) { team.api_client }
  before { allow_any_instance_of(Team).to receive(:api_client).and_return(api_client) }

  let(:options) do
    {
      slack_team_id: team.slack_id,
      slack_caller_id: user.slack_id,
      response_url: "https://api.slack.com/respond_here"
    }
  end

  let(:worker) { StatsWorker.new }

  context "when no bots are involved" do
    let!(:first_place) { user }
    let!(:second_place) { create(:user, team: team, with_sparkles: 10) }
    let!(:third_place) { create(:user, team: team, with_sparkles: 9) }
    let!(:fourth_place) { create(:user, team: team, with_sparkles: 8) }
    let!(:fifth_place) { create(:user, team: team, with_sparkles: 7) }
    let!(:sixth_place) { create(:user, team: team, with_sparkles: 6) }
    let!(:seventh_place) { create(:user, team: team, with_sparkles: 5) }
    let!(:eighth_place) { create(:user, team: team, with_sparkles: 4) }
    let!(:ninth_place) { create(:user, team: team, with_sparkles: 3) }
    let!(:tenth_place) { create(:user, team: team, with_sparkles: 2) }
    let!(:eleventh_place) { teammate }

    context "when used without a provided user_id" do
      it "displays the team leaderboard" do
        expect(worker.http).to receive(:post).with(options[:response_url], {
          response_type: :ephemeral,
          blocks: [
            {
              type: :header,
              text: {
                emoji: true,
                text: ":trophy: Here's the Top 10 Leaderboard for #{team.name}! :trophy:",
                type: :plain_text
              }
            },
            {type: :divider},
            leaderboard_block(first_place),
            leaderboard_block(second_place),
            leaderboard_block(third_place),
            leaderboard_block(fourth_place),
            leaderboard_block(fifth_place),
            leaderboard_block(sixth_place),
            leaderboard_block(seventh_place),
            leaderboard_block(eighth_place),
            leaderboard_block(ninth_place),
            leaderboard_block(tenth_place),
            {type: :divider},
            {
              type: :context,
              elements: [
                {
                  alt_text: "sparkles",
                  image_url: "https://sparkles.lol/sparkles.png",
                  type: :image
                },
                {
                  type: :mrkdwn,
                  text: "Sign in to <https://sparkles.lol/> to see the full leaderboard!"
                }
              ]
            }
          ]
        })

        worker.perform(options)
      end

      context "when the team leaderboard is disabled" do
        before { team.update!(leaderboard_enabled: false) }

        it "defaults to the current user's most recent sparkles" do
          most_recent_sparkles = user.sparkles.includes(:sparkler, :channel).order(created_at: :desc).limit(10)

          expect(worker.http).to receive(:post).with(options[:response_url], {
            response_type: :ephemeral,
            blocks: [
              {
                type: :header,
                text: {
                  text: ":sparkles: Here are your most recent sparkles! :sparkles:",
                  type: :plain_text,
                  emoji: true
                }
              },
              {type: :divider},
              *most_recent_sparkles.map { |s| sparkle_block(s) },
              {type: :divider},
              {
                elements: [
                  {
                    type: :image,
                    image_url: "https://sparkles.lol/sparkles.png",
                    alt_text: "sparkles"
                  },
                  {
                    text: "Visit <https://sparkles.lol/stats/#{team.slack_id}/#{user.slack_id}|sparkles.lol> to see the rest!",
                    type: :mrkdwn
                  }
                ],
                type: :context
              }
            ]
          })

          worker.perform(options)
        end
      end
    end

    context "when a user_id is provided" do
      before { options[:slack_user_id] = teammate.slack_id }

      it "displays that user's sparkles" do
        most_recent_sparkles = teammate.sparkles.includes(:sparkler, :channel).order(created_at: :desc).limit(10)

        expect(worker.http).to receive(:post).with(options[:response_url], {
          response_type: :ephemeral,
          blocks: [
            {
              type: :header,
              text: {
                text: ":sparkles: Here are #{teammate.name}'s most recent sparkles! :sparkles:",
                type: :plain_text,
                emoji: true
              }
            },
            {type: :divider},
            *most_recent_sparkles.map { |s| sparkle_block(s) },
            {type: :divider},
            {
              elements: [
                {
                  type: :image,
                  image_url: "https://sparkles.lol/sparkles.png",
                  alt_text: "sparkles"
                },
                {
                  text: "Visit <https://sparkles.lol/stats/#{team.slack_id}/#{teammate.slack_id}|sparkles.lol> to see the rest!",
                  type: :mrkdwn
                }
              ],
              type: :context
            }
          ]
        })

        worker.perform(options)
      end

      context "when one or more sparkles were given in a private channel" do
        before do
          private_channel = create(:channel, team: team, private: true)
          create(:sparkle, sparkler: user, sparklee: teammate, channel: private_channel, reason: "for your secrets")
        end

        it "hides details about the sparkle from people who are uninvolved" do
          most_recent_sparkles = teammate.sparkles.includes(:sparkler, :channel).order(created_at: :desc).limit(10)

          expect(worker.http).to receive(:post).with(options[:response_url], {
            response_type: :ephemeral,
            blocks: [
              {
                type: :header,
                text: {
                  text: ":sparkles: Here are #{teammate.name}'s most recent sparkles! :sparkles:",
                  type: :plain_text,
                  emoji: true
                }
              },
              {type: :divider},
              *most_recent_sparkles.map { |s| s.channel.private? ? private_sparkle_block(s) : sparkle_block(s) },
              {type: :divider},
              {
                elements: [
                  {
                    type: :image,
                    image_url: "https://sparkles.lol/sparkles.png",
                    alt_text: "sparkles"
                  },
                  {
                    text: "Visit <https://sparkles.lol/stats/#{team.slack_id}/#{teammate.slack_id}|sparkles.lol> to see the rest!",
                    type: :mrkdwn
                  }
                ],
                type: :context
              }
            ]
          })

          worker.perform(options.merge(slack_caller_id: second_place.slack_id))
        end

        it "shows details about the sparkle to the sparkler" do
          most_recent_sparkles = teammate.sparkles.includes(:sparkler, :channel).order(created_at: :desc).limit(10)

          expect(worker.http).to receive(:post).with(options[:response_url], {
            response_type: :ephemeral,
            blocks: [
              {
                type: :header,
                text: {
                  text: ":sparkles: Here are #{teammate.name}'s most recent sparkles! :sparkles:",
                  type: :plain_text,
                  emoji: true
                }
              },
              {type: :divider},
              *most_recent_sparkles.map { |s| sparkle_block(s) },
              {type: :divider},
              {
                elements: [
                  {
                    type: :image,
                    image_url: "https://sparkles.lol/sparkles.png",
                    alt_text: "sparkles"
                  },
                  {
                    text: "Visit <https://sparkles.lol/stats/#{team.slack_id}/#{teammate.slack_id}|sparkles.lol> to see the rest!",
                    type: :mrkdwn
                  }
                ],
                type: :context
              }
            ]
          })

          worker.perform(options.merge(slack_caller_id: user.slack_id))
        end

        it "shows details about the sparkle to the sparklee" do
          most_recent_sparkles = teammate.sparkles.includes(:sparkler, :channel).order(created_at: :desc).limit(10)

          expect(worker.http).to receive(:post).with(options[:response_url], {
            response_type: :ephemeral,
            blocks: [
              {
                type: :header,
                text: {
                  text: ":sparkles: Here are your most recent sparkles! :sparkles:",
                  type: :plain_text,
                  emoji: true
                }
              },
              {type: :divider},
              *most_recent_sparkles.map { |s| sparkle_block(s) },
              {type: :divider},
              {
                elements: [
                  {
                    type: :image,
                    image_url: "https://sparkles.lol/sparkles.png",
                    alt_text: "sparkles"
                  },
                  {
                    text: "Visit <https://sparkles.lol/stats/#{team.slack_id}/#{teammate.slack_id}|sparkles.lol> to see the rest!",
                    type: :mrkdwn
                  }
                ],
                type: :context
              }
            ]
          })

          worker.perform(options.merge(slack_caller_id: teammate.slack_id))
        end
      end

      context "when used on oneself" do
        before { options[:slack_user_id] = user.slack_id }

        it "changes the messaging slightly" do
          most_recent_sparkles = user.sparkles.includes(:sparkler, :channel).order(created_at: :desc).limit(10)

          expect(worker.http).to receive(:post).with(options[:response_url], {
            response_type: :ephemeral,
            blocks: [
              {
                type: :header,
                text: {
                  text: ":sparkles: Here are your most recent sparkles! :sparkles:",
                  type: :plain_text,
                  emoji: true
                }
              },
              {type: :divider},
              *most_recent_sparkles.map { |s| sparkle_block(s) },
              {type: :divider},
              {
                elements: [
                  {
                    type: :image,
                    image_url: "https://sparkles.lol/sparkles.png",
                    alt_text: "sparkles"
                  },
                  {
                    text: "Visit <https://sparkles.lol/stats/#{team.slack_id}/#{user.slack_id}|sparkles.lol> to see the rest!",
                    type: :mrkdwn
                  }
                ],
                type: :context
              }
            ]
          })

          worker.perform(options)
        end
      end
    end
  end

  context "when Sparklebot's ID is provided" do
    before { options[:slack_user_id] = team.sparklebot_id }

    it "posts an error message" do
      expect(worker.http).to receive(:post).with(
        options[:response_url],
        {text: "I have far too many sparkles to count, so I've stopped keeping track! Try this command again with one of your human teammates!", response_type: :ephemeral}
      )

      VCR.use_cassette("stats_sparklebot") { worker.perform(options) }
    end
  end

  context "when Slackbot's ID is provided" do
    before { options[:slack_user_id] = "USLACKBOT" }

    it "posts an error message" do
      expect(worker.http).to receive(:post).with(
        options[:response_url],
        {text: "<@USLACKBOT> and all the other bots have politely declined to join the fun of sparkle hoarding. Try this command again with one of your human teammates!", response_type: :ephemeral}
      )

      VCR.use_cassette("stats_slackbot") { worker.perform(options) }
    end
  end

  context "when a generic bot's ID is provided" do
    before { options[:slack_user_id] = "U02J7PC3Z39" }

    it "posts an error message" do
      expect(worker.http).to receive(:post).with(
        options[:response_url],
        {text: "<@U02J7PC3Z39> and all the other bots have politely declined to join the fun of sparkle hoarding. Try this command again with one of your human teammates!", response_type: :ephemeral}
      )

      VCR.use_cassette("stats_bot") { worker.perform(options) }
    end
  end

  def leaderboard_block(user)
    {
      type: :context,
      elements: [
        image_block(user),
        {
          type: :mrkdwn,
          text: "*<@#{user.slack_id}>* has #{user.sparkles_count} sparkles :sparkles:"
        }
      ]
    }
  end

  def sparkle_block(sparkle)
    {
      type: :context,
      elements: [
        image_block(sparkle.sparkler),
        {
          type: :mrkdwn,
          text: "Sparkled by <@#{sparkle.sparkler.slack_id}> less than a minute ago in <##{sparkle.channel.slack_id}>"
        },
        {
          type: :mrkdwn,
          text: sparkle.reason
        }
      ]
    }
  end

  def private_sparkle_block(sparkle)
    {
      type: :context,
      elements: [
        image_block(sparkle.sparkler),
        {
          type: :mrkdwn,
          text: "Sparkled by <@#{sparkle.sparkler.slack_id}> less than a minute ago in <:lock: a secret place>"
        }
      ]
    }
  end

  def image_block(user)
    {
      type: :image,
      image_url: user.image_url,
      alt_text: user.name
    }
  end
end
