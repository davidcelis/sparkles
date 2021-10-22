module Slack
  class CommandsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :verify_slack_request

    def create
      if matches = params[:text].match(/\A<@(?<user_id>\w+)(?:\|\w+)>( (?<reason>.+))?\z/)
        team = Team.find(params[:team_id])
        slack_client = Slack::Web::Client.new(token: team.slack_token)

        sparkler = team.users.find_or_create_by(id: params[:user_id])
        sparklee = team.users.find_or_create_by(id: matches[:user_id])
        sparkle = sparklee.sparkles.create!(
          sparkler_id: sparkler.id,
          channel_id: params[:channel_id],
          reason: matches[:reason]
        )

        if sparklee.sparkles.count == 1
          response_text = ":tada: <@#{sparklee.id}> just got their first :sparkle:! :tada:"
        else
          response_text = "Thanks for recognizing your teammate! <@#{sparklee.id}> now has #{sparklee.sparkles.count} sparkles :sparkles:"
        end

        render json: {
          response_type: :in_channel,
          text: response_text
        }
      else
        render plain: "Usage: /sparkle @user [reason]"
      end
    end

    private

    def verify_slack_request
      Slack::Events::Request.new(request).verify!
    rescue Slack::Events::Request::MissingSigningSecret
      render json: {error: e.class.name}, status: :bad_request
    end
  end
end
