module Slack
  module SlashCommands
    class Help
      FORMAT = /\Ahelp\z/
      TEXT = <<~USAGE
        *Give someone a sparkle:* `/sparkle @user [reason]` (the reason is optional, so if you want to give someone a :sparkle: for no reason at all, go for it! :smile:)
        *See your team's Top 10 Leaderboard:* `/sparkle stats`
        *Get someone's most recent sparkles:* `/sparkle stats @user`
        *Adjust your experience with Sparkles:* `/sparkle settings`

        You can also see the entire leaderboard and details on every sparkle ever given by signing in at *<https://sparkles.lol>*! Have fun sparkling :sparkles:
      USAGE

      def self.execute(params)
        Result.new(
          response_type: :ephemeral,
          text: "Welcome to Sparkles! I'd be happy to get you started :sparkles:\n\n#{TEXT}"
        )
      end
    end
  end
end
