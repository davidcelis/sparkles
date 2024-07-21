class Team < ApplicationRecord
  has_many :sparkles, dependent: :destroy

  encrypts :access_token

  def api_client
    @api_client ||= Slack::Web::Client.new(token: access_token)
  end
end
