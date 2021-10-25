module Slack
  class EventsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :verify_slack_request

    def create
      type = params.dig(:event, :type)
      klass = "slack/events/#{type}".classify.constantize

      event = klass.new(params)
      event.handle

      if event.result
        render json: event.result
      else
        head :ok
      end
    rescue NameError
      head :bad_request
    end

    private

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    end
  end
end
