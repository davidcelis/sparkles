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
        client_id: Rails.application.credentials.dig(:slack, :client_id),
        client_secret: Rails.application.credentials.dig(:slack, :client_secret),
        redirect_uri: slack_oauth_callback_url
      )

      team = Team.find_or_initialize_by(id: response.team.id)
      team.update!(
        name: response.team.name,
        access_token: response.access_token,
        sparklebot_id: response.bot_user_id,
        active: true
      )

      redirect_to root_path, notice: "Sparkles has been installed to your Slack workspace. Have fun! ✨"
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
