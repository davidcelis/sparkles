# Extensions/overrides for the slack_markdown gem
require 'slack_markdown'

module SlackMarkdown
  module Filters
    class StrikeFilter < ::HTML::Pipeline::Filter
      include IgnorableAncestorTags

      def call
        doc.search('.//text()').each do |node|
          content = node.to_html
          next if has_ancestor?(node, ignored_ancestor_tags)
          next unless content.include?('~')
          html = strike_filter(content)
          next if html == content
          node.replace(html)
        end
        doc
      end

      def strike_filter(text)
        text.gsub(STRIKE_PATTERN) do
          "<strike>#{$1}</strike>"
        end
      end

      STRIKE_PATTERN = /(?<=^|\W)~(.+)~(?=\W|$)/
    end
  end
end

module SlackMarkdown
  module Filters
    class EmojiFilter
      private

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

module SlackMarkdown
  class Processor
    def filters
      @filters ||= [
        SlackMarkdown::Filters::ConvertFilter, # must first run
        SlackMarkdown::Filters::MultipleQuoteFilter,
        SlackMarkdown::Filters::QuoteFilter,
        SlackMarkdown::Filters::MultipleCodeFilter,
        SlackMarkdown::Filters::CodeFilter,
        SlackMarkdown::Filters::EmojiFilter,
        SlackMarkdown::Filters::BoldFilter,
        SlackMarkdown::Filters::ItalicFilter,
        SlackMarkdown::Filters::StrikeFilter,
        SlackMarkdown::Filters::LineBreakFilter,
      ]
    end
  end
end
