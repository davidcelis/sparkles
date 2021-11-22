module Slack
  module SlashCommands
    class Result
      attr_reader :response_type, :text

      def initialize(response_type:, text: nil)
        @response_type = response_type
        @text = text
      end

      def should_render?
        response_type.present?
      end

      def as_json(view_context)
        {response_type: response_type, text: text}.compact
      end
    end
  end
end
