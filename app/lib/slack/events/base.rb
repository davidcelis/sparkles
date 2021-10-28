module Slack
  module Events
    class Base
      attr_reader :slack_team_id
      attr_reader :payload
      attr_reader :result

      def initialize(params)
        @slack_team_id = params[:team_id]
        @payload = params[:event]
      end

      def team
        @team ||= ::Team.find_by!(slack_id: slack_team_id)
      end
    end
  end
end
