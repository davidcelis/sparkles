module Slack
  module Commands
    class GiversLeaderboard
      NUMBERS_TO_EMOJI = Leaderboard::NUMBERS_TO_EMOJI

      def self.execute(params)
        team = Team.find(params[:team_id])

        # Group sparkles by giver (from_user_id) in the last 30 days,
        # then group together ties, same pattern as the existing Leaderboard.
        sparkles = team.sparkles
          .where("created_at >= ?", 30.days.ago)
          .group(:from_user_id)
          .order(count_all: :desc)
          .count
        grouped_sparkles = sparkles.group_by { |_, v| v }.transform_values { |v| v.map(&:first) }

        padding = grouped_sparkles.keys.max.to_s.length

        modal = Slack::Surfaces::Modal.new(title: "Top Givers")
        modal.close(text: "Close")

        modal.blocks.section do |section|
          section.mrkdwn(text: "Here are the most generous sparklers on your team in the last 30 days! :gift:")
        end
        modal.blocks.divider

        grouped_sparkles.each_with_index do |(count, user_ids), index|
          user_ids.sort.each do |user_id|
            rank = (index + 1).to_s
            rank = "0" * (padding - rank.length) + rank
            rank = rank.chars.map { |n| NUMBERS_TO_EMOJI[n] }.join

            modal.blocks.section do |section|
              section.mrkdwn_field(text: "#{rank} <@#{user_id}>:")
              section.mrkdwn_field(text: ":sparkle: gave #{count} #{"sparkle".pluralize(count)}")
            end
          end
        end

        team.api_client.views_open(trigger_id: params[:trigger_id], view: modal.as_json)

        nil
      end
    end
  end
end
