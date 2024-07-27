module Slack
  module Commands
    class Sparkles
      FORMAT = /\A#{Slack::Commands::USER_PATTERN}|me\z/

      HELP_TEXT = <<~TEXT.strip
        Check the leaderboard or view someone’s sparkles! :sparkles:

        Usage: `/sparkles [@user]` (hint: you can also just type `/sparkles me` to see your own sparkles)
      TEXT

      NUMBERS_TO_EMOJI = {
        "0" => ":zero:",
        "1" => ":one:",
        "2" => ":two:",
        "3" => ":three:",
        "4" => ":four:",
        "5" => ":five:",
        "6" => ":six:",
        "7" => ":seven:",
        "8" => ":eight:",
        "9" => ":nine:"
      }

      def self.execute(params)
        text = params[:text].strip
        text = "<@#{params[:user_id]}>" if text == "me"

        match = text.match(FORMAT)

        # If the argument wasn't formatted well or the user ran `/sparkles help`,
        # we'll show the help text.
        if text.strip == "help" || (text.present? && match.nil?)
          return {text: HELP_TEXT, response_type: :ephemeral}
        end

        if match.present?
          render_sparkles_for_user(match[:user_id], params)
        else
          render_leaderboard(params)
        end

        nil
      end

      def self.render_sparkles_for_user(user_id, params)
        team = Team.find(params[:team_id])

        sparkles = team.sparkles.where(user_id: user_id).order(created_at: :desc)

        modal = Slack::Surfaces::Modal.new(title: "Sparkles")
        modal.close(text: "Close")

        modal.blocks.section do |section|
          text = if sparkles.any?
            if user_id == params[:user_id]
              "Here are all the sparkles you’ve received! :sparkles:"
            else
              "Here are all the sparkles that <@#{user_id}> has received! :sparkles:"
            end
          elsif user_id == params[:user_id]
            "You haven’t received any sparkles yet! :cry: Go do something nice or make someone laugh!"
          else
            "<@#{user_id}> hasn’t received any sparkles yet! :cry: Maybe you can change that?"
          end

          section.mrkdwn(text: text)
        end

        modal.blocks.divider if sparkles.any?

        sparkles.each do |sparkle|
          modal.blocks.section do |section|
            from = if sparkle.from_user_id == sparkle.user_id
              if sparkle.from_user_id == params[:user_id]
                "yourself (:wink:)"
              else
                "themselves (:wink:)"
              end
            else
              "<@#{sparkle.from_user_id}>"
            end
            section.mrkdwn(text: ":sparkle: From #{from} in <##{sparkle.channel_id}> on <!date^#{sparkle.created_at.to_i}^{date_short_pretty}^#{sparkle.permalink}|#{sparkle.created_at}>")
          end

          modal.blocks.context { |ctx| ctx.mrkdwn(text: sparkle.reason) } if sparkle.reason.present?
        end

        team.api_client.views_open(trigger_id: params[:trigger_id], view: modal.as_json)
      end

      def self.render_leaderboard(params)
        team = Team.find(params[:team_id])

        # This is a leaderboard, so we'll group the sparkles by user, count
        # them, and then group together any direct ties.
        sparkles = team.sparkles.group(:user_id).order(count_all: :desc).count
        grouped_sparkles = sparkles.group_by { |_, v| v }.transform_values { |v| v.map(&:first) }

        # We're going to show everyone who has ever received a sparkle, and
        # each person will have a rank that we render with emoji numbers.
        # To keep things aligned, we'll left pad the rank with :zero: if we
        # need to.
        padding = grouped_sparkles.keys.max.to_s.length

        modal = Slack::Surfaces::Modal.new(title: "Top Sparklers")
        modal.close(text: "Close")

        modal.blocks.section do |section|
          section.mrkdwn(text: "Here’s the current leaderboard for your team! :sparkles:")
        end
        modal.blocks.divider

        grouped_sparkles.each_with_index do |(count, user_ids), index|
          user_ids.sort.each do |user_id|
            rank = (index + 1).to_s
            rank = "0" * (padding - rank.length) + rank
            rank = rank.chars.map { |n| NUMBERS_TO_EMOJI[n] }.join

            modal.blocks.section do |section|
              section.mrkdwn_field(text: "#{rank} <@#{user_id}>:")
              section.mrkdwn_field(text: ":sparkle: #{count} point".pluralize(count))
            end
          end
        end

        team.api_client.views_open(trigger_id: params[:trigger_id], view: modal.as_json)
      end
    end
  end
end
