module Commands
  module Slack
    ParseError = Class.new(StandardError)

    SPARKLE_USER = /\A<@(?<user_id>\w+)(?:\|\w+)?>( (?<reason>.+))?\z/

    def self.parse(params)
      case params[:text]
      when SPARKLE_USER
        Commands::Slack::Sparkle.new(params)
      else
        raise ParseError
      end
    end
  end
end
