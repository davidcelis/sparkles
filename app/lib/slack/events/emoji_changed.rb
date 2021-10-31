module Slack
  module Events
    class EmojiChanged < Base
      def handle
        EmojiCache.new(team).bust!
      end
    end
  end
end
