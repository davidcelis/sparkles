module Commands
  module Slack
    ParseError = Class.new(StandardError)

    SPARKLE_USER = /\A<@(?<user_id>\w+)(?:\|\w+)?>( (?<reason>.+))?\z/

    def self.parse(text)
      case text
      when SPARKLE_USER
        Commands::Slack::SparkleUser.new(text)
      else
        raise ParseError
      end
    end
  end
end
