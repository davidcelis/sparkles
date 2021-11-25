module Slack
  class OAuthController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:callback]

    before_action :verify_state

    def callback
      # Don't let someone just try to hit the OAuth callback manually and have
      # it send me a dang Sentry email.
      redirect_to root_path and return if params[:code].blank?

      slack_client = Slack::Web::Client.new
      response = slack_client.oauth_v2_access(
        code: params[:code],
        client_id: Slack::CLIENT_ID,
        client_secret: Slack::CLIENT_SECRET,
        redirect_uri: slack_oauth_callback_url
      )

      team = ::Team.find_or_initialize_by(slack_id: response.team.id)
      team.slack_token = response.access_token
      team.sparklebot_id = response.bot_user_id
      team.uninstalled = false

      slack_team = Slack::Team.from_api_response(team.api_client.team_info.team)
      team.assign_attributes(slack_team.attributes)
      team.save!

      user_info_response = team.api_client.users_info(user: response.authed_user.id)
      slack_user = ::Slack::User.from_api_response(user_info_response.user)
      ::User.upsert(slack_user.attributes, unique_by: [:slack_team_id, :slack_id])

      SyncSlackTeamWorker.perform_async(team.id, true)

      cookies.encrypted.permanent[:slack_team_id] = team.slack_id
      cookies.encrypted.permanent[:slack_user_id] = slack_user.slack_id

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
