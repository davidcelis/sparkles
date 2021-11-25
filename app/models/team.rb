class Team < ApplicationRecord
  has_many :users, primary_key: "slack_id", foreign_key: "slack_team_id"
  has_many :channels, primary_key: "slack_id", foreign_key: "slack_team_id"

  scope :active, -> { where(uninstalled: false) }

  def api_client
    @api_client = Slack::Web::Client.new(token: slack_token)
  end
end
