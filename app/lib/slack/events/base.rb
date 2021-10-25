module Slack
  module Events
    class Base
      attr_reader :payload

      def initialize(params)
        @team_id = params[:team_id]
        @payload = params[:event]
      end

      def team
        @team ||= ::Team.find(@team_id)
      end
    end
  end
end
