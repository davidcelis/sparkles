module SlackHelper
  SLACK_AUTHORIZATION_URL = "https://slack.com/oauth/v2/authorize".freeze

  CLIENT_ID = ENV.fetch("SLACK_CLIENT_ID") { Rails.application.credentials.dig(:slack, :client_id) }
  CLIENT_SECRET = ENV.fetch("SLACK_CLIENT_SECRET") { Rails.application.credentials.dig(:slack, :client_secret) }

  BOT_SCOPES = [
    "commands",
    "reactions:read"
  ].freeze

  def add_to_slack_button
    svg = <<~SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" style="height:20px;width:20px;margin-right:12px" viewBox="0 0 122.8 122.8">
        <path d="M25.8 77.6c0 7.1-5.8 12.9-12.9 12.9S0 84.7 0 77.6s5.8-12.9 12.9-12.9h12.9v12.9zm6.5 0c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9v32.3c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V77.6z" fill="#e01e5a"></path>
        <path d="M45.2 25.8c-7.1 0-12.9-5.8-12.9-12.9S38.1 0 45.2 0s12.9 5.8 12.9 12.9v12.9H45.2zm0 6.5c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H12.9C5.8 58.1 0 52.3 0 45.2s5.8-12.9 12.9-12.9h32.3z" fill="#36c5f0"></path>
        <path d="M97 45.2c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9-5.8 12.9-12.9 12.9H97V45.2zm-6.5 0c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V12.9C64.7 5.8 70.5 0 77.6 0s12.9 5.8 12.9 12.9v32.3z" fill="#2eb67d"></path>
        <path d="M77.6 97c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9-12.9-5.8-12.9-12.9V97h12.9zm0-6.5c-7.1 0-12.9-5.8-12.9-12.9s5.8-12.9 12.9-12.9h32.3c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H77.6z" fill="#ecb22e"></path>
      </svg>
    SVG

    style = [
      "align-items: center",
      "color: #000000",
      "background-color: #ffffff",
      "border: 1px solid #dddddd",
      "border-radius: 4px",
      "display: inline-flex",
      "font-family: Lato, sans-serif",
      "font-size: 16px",
      "font-weight: 600",
      "height: 48px",
      "justify-content: center",
      "text-decoration: none",
      "width: 236px",
    ].join(";")

    authorization_url = URI(SLACK_AUTHORIZATION_URL)
    authorization_url.query = {
      scope: BOT_SCOPES.join(","),
      redirect_uri: "https://215c-71-36-123-150.ngrok.io/slack/oauth/callback", # slack_oauth_callback_url,
      client_id: CLIENT_ID
    }.to_query

    link_to "#{svg} Add to Slack".html_safe, authorization_url.to_s, style: style
  end
end
