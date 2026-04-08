class Team < ApplicationRecord
  has_many :sparkles, dependent: :destroy
  has_many :sparkle_reminders, dependent: :destroy

  encrypts :access_token

  def api_client
    @api_client ||= Slack::Web::Client.new(token: access_token)
  end
end
