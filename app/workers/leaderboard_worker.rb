class LeaderboardWorker < ApplicationWorker
  include ActionView::Helpers::DateHelper

  def perform(options)
    options = options.with_indifferent_access
    team = Team.find_by!(slack_id: options[:slack_team_id])

    blocks = if options[:slack_user_id]
      user_stats_for(team: team, slack_user_id: options[:slack_user_id])
    else
      team_leaderboard_for(team: team)
    end

    http.post(options[:response_url], {blocks: blocks, response_type: :ephemeral})
  end

  private

  def team_leaderboard_for(team:)
    users = team.users.where(deactivated: false).order(sparkles_count: :desc).limit(10)

    blocks = [
      {
        type: :header,
        text: {
          type: :plain_text,
          text: ":trophy: Here's the Top 10 Leaderboard for #{team.name}! :trophy:",
          emoji: true
        }
      },
      {type: :divider}
    ]
    users.each_with_index do |user, i|
      blocks << {
        type: :context,
        elements: [
          {
            type: :image,
            image_url: user.image_url,
            alt_text: user.name
          },
          {
            type: :mrkdwn,
            text: "*<@#{user.slack_id}>* has #{user.sparkles_count} sparkles :sparkles:"
          }
        ]
      }
    end

    blocks << {type: :divider}
    blocks << {
      type: :context,
      elements: [
        {
          type: :image,
          image_url: "https://sparkles.lol/sparkles.png",
          alt_text: "sparkles"
        },
        {
          type: :mrkdwn,
          text: "Sign in to <https://sparkles.lol/> to see the full leaderboard!"
        }
      ]
    }

    blocks
  end

  def user_stats_for(team:, slack_user_id:)
    response = team.api_client.users_info(user: slack_user_id)
    slack_user = Slack::User.from_api_response(response.user)

    if slack_user.bot?
      text = if slack_user.sparklebot?
        "I have far too many sparkles to count, so I've stopped keeping track!"
      else
        "<@#{slack_user_id}> and all the other bots have politely declined to join the fun of sparkle hoarding."
      end

      text += " Try this command again with one of your human teammates!"

      return text
    end

    # Fetch the user from our database, updating their info if it's behind
    user = team.users.find_or_initialize_by(slack_id: slack_user_id)
    user.update!(slack_user.attributes) if user.new_record?
    sparkles = user.sparkles.includes(:sparkler, :channel).order(created_at: :desc).limit(10)

    blocks = [
      {
        type: :header,
        text: {
          type: :plain_text,
          text: ":sparkles: Here are the most recent sparkles given to #{user.name}! :sparkles:",
          emoji: true
        }
      },
      {type: :divider}
    ]

    sparkles.each do |sparkle|
      channel_text = if sparkle.channel.private?
        "a secret place :lock:"
      else
        "<##{sparkle.channel.slack_id}>"
      end

      time_text = "#{time_ago_in_words(sparkle.created_at)} ago"
      if !sparkle.channel.private? && sparkle.permalink.present?
        time_text = "<#{sparkle.permalink}|#{time_text}>"
      end
      reason_text = " (#{sparkle.reason})" if sparkle.reason.present?

      text = "Sparkled by <@#{sparkle.sparkler.slack_id}> #{time_text} in #{channel_text}#{reason_text}"

      blocks << {
        type: :context,
        elements: [
          {
            type: :image,
            image_url: sparkle.sparkler.image_url,
            alt_text: sparkle.sparkler.name
          },
          {
            type: :mrkdwn,
            text: text
          }
        ]
      }
    end

    blocks << {type: :divider}
    blocks << {
      type: :context,
      elements: [
        {
          type: :image,
          image_url: "https://sparkles.lol/sparkles.png",
          alt_text: "sparkles"
        },
        {
          type: :mrkdwn,
          text: "Visit <https://sparkles.lol/leaderboard/#{team.slack_id}/#{user.slack_id}|sparkles.lol> to see the rest!"
        }
      ]
    }

    blocks
  end

  def http
    @http ||= Faraday.new do |f|
      f.request :json # Encode request bodies as JSON
      f.request :retry # Retry transient failures
    end
  end
end
