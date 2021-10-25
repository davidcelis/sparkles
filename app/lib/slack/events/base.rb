module Slack
  module Events
    class Base
      attr_reader :payload
      attr_reader :team_id

      def initialize(params)
        @team_id = params[:team_id]
        @payload = params[:event]
      end
    end
  end
end
