module Slack
  class CommandsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :verify_slack_request

    def create
      text = params.delete(:text)
      result = Commands::Slack.parse(text).execute(params)

      render json: result
    rescue Commands::Slack::ParseError
      render plain: "Sorry, I didn't understand your command.\n\nUsage: /sparkle @user [reason]"
    end

    private

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    rescue Slack::Events::Request::MissingSigningSecret
      render json: {error: e.class.name}, status: :bad_request
    end
  end
end
