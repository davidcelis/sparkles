module Slack
  class CommandsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :verify_slack_request
    before_action :verify_channel_supports_sparkles

    def create
      command = Slack::SlashCommands.parse(params)
      command.execute

      if command.result.present?
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

    def verify_channel_supports_sparkles
      channel = ::Channel.find_by!(slack_team_id: params[:team_id], slack_id: params[:channel_id])
      unless channel.supports_sparkles?
        render json: {response_type: :ephemeral, text: "Sorry, but I don't work in shared or read-only channels :sweat:"}
      end
    rescue ActiveRecord::RecordNotFound
      render json: {response_type: :ephemeral, text: "Oops! You need to `/invite` me to this channel before I can work here :sweat_smile:"}
    end
  end
end
