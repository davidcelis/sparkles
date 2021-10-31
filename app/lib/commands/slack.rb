module Commands
  module Slack
    ParseError = Class.new(StandardError)

    SPARKLE_USER = /\A#{SlackHelper::USER_PATTERN}(\s+(?<reason>.+))?\z/
    LEADERBOARD = /\Astats(\s+<@(?<slack_user_id>\w+)(?:\|\w+)?>)?\z/
    HELP = /\Ahelp\z/

    def self.parse(params)
      case params[:text]
      when SPARKLE_USER
        Commands::Slack::Sparkle.new(params)
      when LEADERBOARD
        Commands::Slack::Leaderboard.new(params)
      when HELP
        Commands::Slack::Help.new(params)
      else
        raise ParseError
      end
    end
  end
end
