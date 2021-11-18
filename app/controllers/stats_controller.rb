class StatsController < ApplicationController
  before_action :require_authentication

  def team
    if leaderboard_enabled?
      @high_score = current_team.users.where(deactivated: false).maximum(:sparkles_count)
      @users = current_team.users.where(deactivated: false).order(sparkles_count: :desc).page(params[:page]).per(100)

      render :leaderboard
    else
      @users = current_team.users.where(deactivated: false).order(:name).page(params[:page]).per(100)

      render :team
    end
  end

  def user
    raise ActiveRecord::RecordNotFound unless current_team.slack_id == params[:slack_team_id]

    @user = current_team.users.find_by!(slack_id: params[:slack_user_id])
    @sparkles = @user.sparkles.includes(:sparkler, :channel).order(created_at: :desc).page(params[:page]).per(25)

    # The Slack Markdown Processor allows us to render each sparkle's reason
    # in just the way the original user intended it to be seen.
    @processor = markdown_processor_for(@sparkles)
  end

  private

  def markdown_processor_for(sparkles)
    reasons = sparkles.map(&:reason).compact

    # Parse out the users and channels that are being mentioned in the sparkles
    # we're going to render. This keeps us from having to query for _all_ of a
    # team's users or channels when we're likely only rendering a very small
    # number, if any at all, user or channel mentions.
    mentioned_user_ids = reasons.map { |r| r.scan(SlackHelper::USER_PATTERN) }.flatten
    user_ids_to_names = current_team.users.where(slack_id: mentioned_user_ids).pluck(:slack_id, :name, :username).map do |(slack_id, name, username)|
      [slack_id, username || name]
    end.to_h
    mentioned_channel_ids = reasons.map { |r| r.scan(SlackHelper::CHANNEL_PATTERN) }.flatten
    channel_ids_to_names = current_team.channels.where(slack_id: mentioned_channel_ids).pluck(:slack_id, :name, :private).map do |(slack_id, name, private)|
      [slack_id, (private ? "<🔒 somewhere secret>" : name)]
    end.to_h

    # Likewise, workspaces can have tens of thousands of custom emoji, so
    # instead of initializing a huge hash and letting the markdown processor's
    # emoji filter create a huge regex from it, quickly parse through the
    # reasons we're going to render and figure out which emoji they might
    # contain, making sure not to include emoji from the default set.
    possible_emoji = reasons.map { |r| r.scan(SlackHelper::EMOJI_PATTERN) }
      .flatten
      .reject(&:blank?)
      .difference(SlackHelper::STOCK_EMOJI_NAMES)
    emoji_set = EmojiCache.new(current_team).read(*possible_emoji)

    SlackMarkdown::Processor.new(
      on_slack_user_id: ->(id) {
        return {url: user_stats_path(current_team.slack_id, id), text: user_ids_to_names[id]}
      },
      on_slack_channel_id: ->(id) {
        return {url: "#", text: channel_ids_to_names[id]}
      },
      asset_root: "/assets",
      original_emoji_set: emoji_set
    )
  end
end
