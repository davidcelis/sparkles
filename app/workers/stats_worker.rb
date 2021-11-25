class StatsWorker < ApplicationWorker
  include ActionView::Helpers::DateHelper

  def perform(options)
    options = options.with_indifferent_access
    team = Team.find_by!(slack_id: options[:slack_team_id])
    current_user = team.users.find_by!(slack_id: options[:slack_caller_id])

    result = if options[:slack_user_id]
      user_stats_for(team: team, current_user: current_user, slack_user_id: options[:slack_user_id])
    elsif team.leaderboard_enabled? && current_user.leaderboard_enabled?
      team_leaderboard_for(team: team)
    else
      user_stats_for(team: team, current_user: current_user, slack_user_id: current_user.slack_id)
    end

    http.post(options[:response_url], result)
  end

  def http
    @http ||= Faraday.new do |f|
      f.request :json # Encode request bodies as JSON
      f.request :retry # Retry transient failures
    end
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

    {blocks: blocks, response_type: :ephemeral}
  end

  def user_stats_for(team:, current_user:, slack_user_id:)
    user = if current_user.slack_id == slack_user_id
      current_user
    else
      team.users.find_by(slack_id: slack_user_id)
    end

    unless user
      response = team.api_client.users_info(user: slack_user_id)
      slack_user = Slack::User.from_api_response(response.user)

      if slack_user.bot?
        text = if slack_user.slack_id == team.sparklebot_id
          "I have far too many sparkles to count, so I've stopped keeping track!"
        else
          "<@#{slack_user_id}> and all the other bots have politely declined to join the fun of sparkle hoarding."
        end

        text += " Try this command again with one of your human teammates!"

        return {text: text, response_type: :ephemeral}
      end

      # Fetch the user from our database, updating their info if it's behind
      user = team.users.find_or_initialize_by(slack_id: slack_user_id)
      user.update!(slack_user.attributes) if user.new_record?
    end

    sparkles = user.sparkles.includes(:sparkler, :channel).order(created_at: :desc).limit(10)
    header = current_user == user ? "Here are your most recent sparkles!" : "Here are #{user.name}'s most recent sparkles!"
    blocks = [
      {
        type: :header,
        text: {
          type: :plain_text,
          text: ":sparkles: #{header} :sparkles:",
          emoji: true
        }
      },
      {type: :divider}
    ]

    sparkles.each do |sparkle|
      channel_text = if sparkle.visible_to?(current_user)
        "<##{sparkle.channel.slack_id}>"
      else
        "<:lock: a secret place>"
      end

      time_text = "#{time_ago_in_words(sparkle.created_at)} ago"
      if !sparkle.channel.private? && sparkle.permalink.present?
        time_text = "<#{sparkle.permalink}|#{time_text}>"
      end

      text = "Sparkled by <@#{sparkle.sparkler.slack_id}> #{time_text} in #{channel_text}"

      block = {
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

      if sparkle.reason.present? && sparkle.visible_to?(current_user)
        block[:elements] << {type: :mrkdwn, text: sparkle.reason}
      end

      blocks << block
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
          text: "Visit <https://sparkles.lol/stats/#{team.slack_id}/#{user.slack_id}|sparkles.lol> to see the rest!"
        }
      ]
    }

    {blocks: blocks, response_type: :ephemeral}
  end
end
