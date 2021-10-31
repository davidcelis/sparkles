# Extensions/overrides for the slack_markdown gem
require "slack_markdown"

module SlackMarkdown
  module Filters
    class EmojiFilter
      private

      # We only need to generate <img> tags for custom emoji. Anything in the
      # open Unicode specification should just get rendered as raw unicode.
      def emoji_image_tag(name)
        if (emoji = Emoji.find_by_alias(name))
          emoji.raw
        else
          super(name)
        end
      end
    end
  end
end
