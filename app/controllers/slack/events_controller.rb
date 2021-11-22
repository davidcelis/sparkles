module Slack
  class EventsController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_slack_request
    before_action :handle_url_verification, if: -> { params[:type] == "url_verification" }

    def create
      event = "slack/events/#{event_type}".classify.constantize
      event.execute(slack_team_id: params[:team_id], payload: params[:event])

      head :ok
    rescue NameError
      head :bad_request
    end

    private

    def event_type
      @event_type ||= params.dig(:event, :type)
    end

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    rescue Slack::Events::Request::MissingSigningSecret, Slack::Events::Request::TimestampExpired, Slack::Events::Request::InvalidSignature
      head :bad_request
    end

    def handle_url_verification
      render plain: params[:challenge]
    end
  end
end
