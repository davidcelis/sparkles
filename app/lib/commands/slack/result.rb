module Commands
  module Slack
    class Result
      def initialize(text:, blocks: nil, response_type: :ephemeral)
        @text = text
        @blocks = blocks
        @response_type = response_type
      end

      def as_json(options = {})
        {
          text: @text,
          blocks: @blocks,
          response_type: @response_type
        }.compact.as_json(options)
      end
    end
  end
end
