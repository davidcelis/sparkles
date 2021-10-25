module Commands
  module Slack
    class Base
      attr_reader :params
      attr_reader :result

      def initialize(params)
        @params = params
      end
    end
  end
end
