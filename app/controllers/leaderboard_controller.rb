class LeaderboardController < ApplicationController
  before_action :require_authentication

  def show
    @high_score = User.maximum(:sparkles_count)
    @users = User.order(sparkles_count: :desc).page(params[:page]).per(100)
  end

  def details
    raise ActiveRecord::RecordNotFound unless current_team.slack_id == params[:slack_team_id]

    @user = current_team.users.find_by!(slack_id: params[:slack_user_id])
    @sparkles = @user.sparkles.includes(:sparkler, :channel).order(created_at: :desc).page(params[:page]).per(25)

    # Create a Slack Markdown formatter so that we can show sparkle reasons properly!
    user_map = Hash[current_team.users.pluck(:slack_id, :name, :username).map do |(slack_id, name, username)|
      [slack_id, username || name]
    end]
    channel_map = Hash[current_team.channels.pluck(:slack_id, :name, :private).map do |(slack_id, name, private)|
      [slack_id, (private ? "<🔒 somewhere secret>" : name)]
    end]
    emoji_response = current_team.api_client.emoji_list
    @processor = SlackMarkdown::Processor.new(
      on_slack_user_id: ->(id) {
        return { url: "#" , text: user_map[id] }
      },
      on_slack_channel_id: ->(id) {
        return { url: "#" , text: channel_map[id] }
      },
      asset_root: '/assets',
      original_emoji_set: emoji_response.emoji
    )
  end
end
