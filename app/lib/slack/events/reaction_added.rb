module Slack
  module Events
    class ReactionAdded
      def self.process(team_id:, payload:)
        return unless payload[:reaction] == "sparkle" && payload.dig(:item, :type) == "message"

        SparkleJob.perform_later(
          team_id: team_id,
          recipient_id: payload[:item_user],
          user_id: payload[:user],
          channel_id: payload.dig(:item, :channel),
          reaction_to_ts: payload.dig(:item, :ts)
        )
      end
    end
  end
end
