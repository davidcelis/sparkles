module Slack
  class InteractionsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :verify_slack_request

    def create
      payload = JSON.parse(params[:payload]).with_indifferent_access

      # We only care about modifying settings if the view was submitted.
      return head :ok unless payload[:type] == "view_submission"

      team = ::Team.find_by!(slack_id: payload.dig(:team, :id))
      user = team.users.find_by!(slack_id: payload.dig(:user, :id))

      # Pull the values from the final state of the view when it was submitted.
      values = payload.dig(:view, :state, :values).map { |_, v| v.first }.to_h.with_indifferent_access

      # Adjust the user's personal leaderboard setting.
      user_leaderboard_enabled = values.dig(:user_leaderboard_enabled, :selected_options).present?
      user.update!(leaderboard_enabled: user_leaderboard_enabled)

      # Adjust the team's settings if the user was an admin
      if user.team_admin?
        team_leaderboard_enabled = values.dig(:team_leaderboard_enabled, :selected_options).present?
        slack_feed_channel_id = values.dig(:team_sparkle_feed_channel, :selected_channel)

        team.update!(leaderboard_enabled: team_leaderboard_enabled, slack_feed_channel_id: slack_feed_channel_id)
      end

      head :ok
    end

    private

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    rescue Slack::Events::Request::MissingSigningSecret, Slack::Events::Request::TimestampExpired, Slack::Events::Request::InvalidSignature
      head :bad_request
    end
  end
end
