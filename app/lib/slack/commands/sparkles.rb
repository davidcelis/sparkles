module Slack
  module Commands
    class Sparkles
      FORMAT = /\A#{Slack::Commands::USER_PATTERN}|me\z/

      HELP_TEXT = <<~TEXT.strip
        Check the leaderboard or view someone’s sparkles! :sparkles:

        Usage: `/sparkles [@user]` (hint: you can also just type `/sparkles me` to see your own sparkles)
      TEXT

      def self.execute(params)
        text = params[:text].strip
        text = "<@#{params[:user_id]}>" if text == "me"

        match = text.match(FORMAT)

        # If the argument wasn't formatted well or the user ran `/sparkles help`,
        # we'll show the help text.
        if text.strip == "help" || (text.present? && match.nil?)
          return {text: HELP_TEXT, response_type: :ephemeral}
        end

        return Leaderboard.execute(params) if match.nil?

        team = Team.find(params[:team_id])
        user_id = match[:user_id]

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
            section.mrkdwn(text: ":sparkle: From #{from} in <##{sparkle.channel_id}> on <!date^#{sparkle.created_at.to_i}^{date_short}^#{sparkle.permalink}|#{sparkle.created_at}>")
          end

          modal.blocks.context { |ctx| ctx.mrkdwn(text: sparkle.reason) } if sparkle.reason.present?
        end

        team.api_client.views_open(trigger_id: params[:trigger_id], view: modal.as_json)

        nil
      end
    end
  end
end
