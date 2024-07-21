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

        # TODO: Implement the leaderboard and user-specific sparkles. For now,
        # just say it's coming soon.
        {text: ":construction: This feature is coming soon!", response_type: :ephemeral}
      end
    end
  end
end
