module Slack
  class CommandsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :verify_slack_request

    def create
      command = Slack::SlashCommands.parse(params)
      command.execute

      if command.result
        render json: command.result
      else
        head :ok
      end
    rescue Slack::SlashCommands::ParseError
      render plain: "Sorry, I didn't understand your command. Usage:\n\n#{Slack::SlashCommands::Help::TEXT}"
    end

    private

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    rescue Slack::Events::Request::MissingSigningSecret, Slack::Events::Request::TimestampExpired, Slack::Events::Request::InvalidSignature
      render plain: "Oops! I ran into an error verifying this request, but you should try again in a sec."
    end
  end
end
