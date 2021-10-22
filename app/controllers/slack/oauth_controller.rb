module Slack
  class OAuthController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:callback]

    def install
    end

    def callback
      slack_client = Slack::Web::Client.new
      response = slack_client.oauth_v2_access(
        code: params[:code],
        client_id: SlackHelper::CLIENT_ID,
        client_secret: SlackHelper::CLIENT_SECRET,
      )

      team = Team.find_or_initialize_by(id: response.team.id)
      team.slack_token = response.access_token
      team.save!

      user = User.find_or_create_by(id: response.authed_user.id, team_id: team.id)
      cookies.permanent.signed[:user_id] = user.id

      redirect_to root_path
    end
  end
end
