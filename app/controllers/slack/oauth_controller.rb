module Slack
  class OAuthController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:callback]

    before_action :verify_state

    def callback
      slack_client = Slack::Web::Client.new
      response = slack_client.oauth_v2_access(
        code: params[:code],
        client_id: Rails.application.credentials.dig(:slack, :client_id),
        client_secret: Rails.application.credentials.dig(:slack, :client_secret),
        redirect_uri: slack_oauth_callback_url,
      )

      team = ::Team.find_or_initialize_by(id: response.team.id)
      user = ::User.find_or_initialize_by(id: response.authed_user.id, team_id: team.id)

      ActiveRecord::Base.transaction do
        team.update!(slack_token: response.access_token, sparklebot_id: response.bot_user_id)
        user.update!(slack_token: response.authed_user.access_token)
      end

      SyncSlackTeamWorker.perform_async(team.id, true)

      cookies.encrypted.permanent[:team_id] = user.team_id
      cookies.encrypted.permanent[:user_id] = user.id

      redirect_to root_path
    end

    private

    def verify_state
      if cookies.encrypted[:state] != params[:state]
        flash.alert = "The provided OAuth state did not match. Please try installing to Slack again."

        redirect_to root_path
      end
    end
  end
end
