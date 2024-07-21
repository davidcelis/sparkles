module Slack
  module Commands
    Error = Class.new(StandardError)

    USER_PATTERN = /<@(?<user_id>\w+)(?:\|[^>]*)?>/

    REGISTRY = {
      "/sparkle" => Slack::Commands::Sparkle,
      "/sparkles" => Slack::Commands::Sparkles
    }

    def self.find(command)
      REGISTRY[command]
    end
  end
end
