module Slack
  module Commands
    Error = Class.new(StandardError)

    REGISTRY = {
      "/sparkle" => Slack::Commands::Sparkle
    }

    def self.find(command)
      REGISTRY[command]
    end
  end
end
