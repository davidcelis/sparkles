module Slack
  module Events
    class EmojiChanged
      def self.execute(slack_team_id:, payload:)
        team = ::Team.find_by!(slack_id: slack_team_id)
        EmojiCache.new(team).bust!
      end
    end
  end
end
