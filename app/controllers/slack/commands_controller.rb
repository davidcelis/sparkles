module Slack
  class CommandsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :verify_slack_request

    def create
      render plain: "Thanks for recognizing your teammate!"
    end

    private

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    rescue Slack::Events::Request::MissingSigningSecret
      render json: {error: e.class.name}, status: :bad_request
    end
  end
end
