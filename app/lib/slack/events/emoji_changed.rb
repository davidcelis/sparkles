module Slack
  module Events
    class EmojiChanged < Base
      def handle
        # We bust the entire cache for a team on any emoji change because it's
        # easy, but we _could_ actually handle each sub-type and either add,
        # modify, or delete the one emoji that was changed.
        EmojiCache.new(team).bust!
      end
    end
  end
end
