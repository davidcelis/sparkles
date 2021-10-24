class Team < ApplicationRecord
  has_many :channels
  has_many :users

  def api_client
    @api_client = Slack::Web::Client.new(token: slack_token)
  end
end
