module Slack
  class CommandsController < ApplicationController
    ParseError = Class.new(StandardError)

    skip_before_action :verify_authenticity_token
    before_action :verify_slack_request
    before_action :verify_channel_supports_sparkles

    def create
      command_class = parse(params[:text])
      result = command_class.execute(params.except(:controller, :action).to_unsafe_h)

      return head :ok unless result.should_render?

      render json: result
    rescue ParseError
      render plain: "Sorry, I didn't understand your command. Usage:\n\n#{Slack::SlashCommands::Help::TEXT}"
    end

    private

    def parse(text)
      case params[:text]
      when Slack::SlashCommands::Sparkle::FORMAT
        Slack::SlashCommands::Sparkle
      when Slack::SlashCommands::Stats::FORMAT
        Slack::SlashCommands::Stats
      when Slack::SlashCommands::Settings::FORMAT
        Slack::SlashCommands::Settings
      when Slack::SlashCommands::Help::FORMAT
        Slack::SlashCommands::Help
      else
        raise ParseError
      end
    end

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    rescue Slack::Events::Request::TimestampExpired
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
