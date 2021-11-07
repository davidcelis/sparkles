module Slack
  class InteractionsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :verify_slack_request

    def create
      head :ok
    end

    private

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    end
  end
end
