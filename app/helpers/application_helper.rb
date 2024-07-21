module ApplicationHelper
  SLACK_OAUTH_URL = "https://slack.com/oauth/v2/authorize".freeze

  BOT_SCOPES = [
    "chat:write",
    "commands",
    "reactions:read",
    "users:read"
  ].freeze

  def slack_authorization_url(state:)
    authorization_url = URI(SLACK_OAUTH_URL)
    authorization_url.query = {
      scope: BOT_SCOPES.join(","),
      client_id: Rails.application.credentials.dig(:slack, :client_id),
      state: state,
      redirect_uri: slack_oauth_callback_url
    }.to_query

    authorization_url.to_s
  end
end
