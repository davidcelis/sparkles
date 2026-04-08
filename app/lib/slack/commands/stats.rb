module Slack
  module Commands
    class Stats
      def self.execute(params)
        team = Team.find(params[:team_id])

        # Parse optional number of days from the text (default: 30)
        text = params[:text].to_s.sub(/\Astats\s*/, "").strip
        days = text.present? ? text.to_i : 30
        days = 30 if days <= 0 || days > 365

        since = days.days.ago
        sparkles = team.sparkles.where("created_at >= ?", since)

        total_sparkles = sparkles.count
        unique_receivers = sparkles.distinct.count(:user_id)
        unique_givers = sparkles.distinct.count(:from_user_id)

        # Top 5 receivers
        top_receivers = sparkles
          .group(:user_id)
          .order(count_all: :desc)
          .limit(5)
          .count

        # Top 5 givers
        top_givers = sparkles
          .group(:from_user_id)
          .order(count_all: :desc)
          .limit(5)
          .count

        modal = Slack::Surfaces::Modal.new(title: "Sparkle Stats")
        modal.close(text: "Close")

        modal.blocks.section do |section|
          section.mrkdwn(text: ":bar_chart: *Sparkle Stats* for the last #{days} days")
        end

        modal.blocks.section do |section|
          section.mrkdwn(text: [
            ":sparkles: *#{total_sparkles}* total sparkles given",
            ":busts_in_silhouette: *#{unique_receivers}* people received sparkles",
            ":gift: *#{unique_givers}* people gave sparkles"
          ].join("\n"))
        end

        modal.blocks.divider

        # Top receivers section
        modal.blocks.section do |section|
          section.mrkdwn(text: ":trophy: *Top Receivers*")
        end

        top_receivers.each_with_index do |(user_id, count), index|
          medal = case index
          when 0 then ":first_place_medal:"
          when 1 then ":second_place_medal:"
          when 2 then ":third_place_medal:"
          else "#{index + 1}."
          end

          modal.blocks.section do |section|
            section.mrkdwn_field(text: "#{medal} <@#{user_id}>")
            section.mrkdwn_field(text: ":sparkle: #{count} #{"sparkle".pluralize(count)}")
          end
        end

        modal.blocks.divider

        # Top givers section
        modal.blocks.section do |section|
          section.mrkdwn(text: ":gift: *Top Givers*")
        end

        top_givers.each_with_index do |(user_id, count), index|
          medal = case index
          when 0 then ":first_place_medal:"
          when 1 then ":second_place_medal:"
          when 2 then ":third_place_medal:"
          else "#{index + 1}."
          end

          modal.blocks.section do |section|
            section.mrkdwn_field(text: "#{medal} <@#{user_id}>")
            section.mrkdwn_field(text: ":sparkle: #{count} #{"sparkle".pluralize(count)}")
          end
        end

        team.api_client.views_open(trigger_id: params[:trigger_id], view: modal.as_json)

        nil
      end
    end
  end
end
