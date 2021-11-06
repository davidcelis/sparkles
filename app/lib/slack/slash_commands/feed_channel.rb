module Slack
  module SlashCommands
    class FeedChannel < Base
      def execute
        matches = params[:text].match(Slack::SlashCommands::FEED_CHANNEL)
        options = {
          slack_team_id: params[:team_id],
          slack_channel_id: params[:channel_id],
          feed_slack_channel_id: matches[:slack_channel_id]
        }

        FeedChannelWorker.perform_async(options)
      end
    end
  end
end
