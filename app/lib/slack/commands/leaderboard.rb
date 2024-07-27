module Slack
  module Commands
    class Leaderboard
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

        nil
      end
    end
  end
end
