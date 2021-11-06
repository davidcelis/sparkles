module Slack
  module SlashCommands
    class Help < Base
      TEXT = <<~USAGE
        *Give someone a sparkle:* `/sparkle @user [reason]` (the reason is optional, so if you want to give someone a :sparkle: for no reason at all, go for it! :smile:)
        *See your team's Top 10 Leaderboard:* `/sparkle stats`
        *Get someone's most recent sparkles:* `/sparkle stats @user`
        *Set a channel to send public sparkles:* `/sparkle set feed #channel`

        You can also see the entire leaderboard and details on every sparkle ever given by signing in at *<https://sparkles.lol>*! Have fun sparkling :sparkles:
      USAGE

      def execute
        text = "Welcome to Sparkles! I'd be happy to get you started :sparkles:\n\n#{TEXT}"
        @result = {response_type: :ephemeral, text: text}
      end
    end
  end
end
