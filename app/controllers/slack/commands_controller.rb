module Slack
  class CommandsController < ApplicationController
    ParseError = Class.new(StandardError)

    skip_before_action :verify_authenticity_token
    before_action :verify_slack_request

    def create
      command_class = Slack::Commands.find(params[:command])
      result = command_class.execute(params.except(:command, :controller, :action).to_unsafe_h)

      return head :accepted unless result.present?

      render json: result
    end

    private

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    rescue Slack::Events::Request::TimestampExpired
      render json: {text: "Oops! I ran into an error verifying this request, but you should try again in a sec."}
    end
  end
end
