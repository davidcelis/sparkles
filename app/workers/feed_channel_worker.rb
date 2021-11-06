class FeedChannelWorker < ApplicationWorker

  def perform(options)
    options = options.with_indifferent_access
    team = Team.find_by!(slack_id: options[:slack_team_id])
    channel = team.channels.find_by!(slack_id: options[:slack_channel_id])
    feed_channel = team.channels.find_by!(slack_id: options[:feed_slack_channel_id])

    team.update(slack_feed_channel_id: feed_channel.slack_id)

    team.api_client.chat_postMessage(
      channel: channel.slack_id,
      text: "<##{feed_channel.slack_id}> has been set as the current feed channel!"
    )
  end

end