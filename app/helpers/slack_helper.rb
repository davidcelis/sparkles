module SlackHelper
  SLACK_OAUTH_URL = "https://slack.com/oauth/v2/authorize".freeze
  SLACK_OPENID_URL = "https://slack.com/openid/connect/authorize".freeze

  BOT_SCOPES = [
    "channels:join",
    "channels:read",
    "commands",
    "groups:read",
    "team:read",
    "users:read"
  ].freeze

  USER_SCOPES = ["openid"].freeze

  def sign_in_with_slack_button(state:, nonce:)
    authorization_url = URI(SLACK_OPENID_URL)
    authorization_url.query = {
      response_type: :code,
      scope: USER_SCOPES.join(","),
      client_id: Rails.application.credentials.dig(:slack, :client_id),
      state: state,
      nonce: nonce,
      redirect_uri: slack_openid_callback_url
    }.to_query

    link_to "#{slack_button_svg(size: "24px")} Sign in with Slack".html_safe, authorization_url.to_s, style: sign_in_with_slack_style_tags
  end

  def add_to_slack_button(state:)
    authorization_url = URI(SLACK_OAUTH_URL)
    authorization_url.query = {
      scope: BOT_SCOPES.join(","),
      user_scope: USER_SCOPES.join(","),
      client_id: Rails.application.credentials.dig(:slack, :client_id),
      state: state,
      redirect_uri: slack_oauth_callback_url
    }.to_query

    link_to "#{slack_button_svg(size: "16px")} Add to Slack".html_safe, authorization_url.to_s, style: add_to_slack_style_tags
  end

  private

  def slack_button_svg(size:)
    <<~SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" style="height:#{size};width:#{size};margin-right:12px" viewBox="0 0 122.8 122.8">
        <path d="M25.8 77.6c0 7.1-5.8 12.9-12.9 12.9S0 84.7 0 77.6s5.8-12.9 12.9-12.9h12.9v12.9zm6.5 0c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9v32.3c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V77.6z" fill="#e01e5a"></path>
        <path d="M45.2 25.8c-7.1 0-12.9-5.8-12.9-12.9S38.1 0 45.2 0s12.9 5.8 12.9 12.9v12.9H45.2zm0 6.5c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H12.9C5.8 58.1 0 52.3 0 45.2s5.8-12.9 12.9-12.9h32.3z" fill="#36c5f0"></path>
        <path d="M97 45.2c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9-5.8 12.9-12.9 12.9H97V45.2zm-6.5 0c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V12.9C64.7 5.8 70.5 0 77.6 0s12.9 5.8 12.9 12.9v32.3z" fill="#2eb67d"></path>
        <path d="M77.6 97c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9-12.9-5.8-12.9-12.9V97h12.9zm0-6.5c-7.1 0-12.9-5.8-12.9-12.9s5.8-12.9 12.9-12.9h32.3c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H77.6z" fill="#ecb22e"></path>
      </svg>
    SVG
  end

  def sign_in_with_slack_style_tags
    size_tags = [
      "font-size: 18px",
      "height: 56px",
      "width: 296px"
    ]

    (slack_button_style_tags + size_tags).join(";")
  end

  def add_to_slack_style_tags
    size_tags = [
      "font-size: 14px",
      "height: 44px",
      "width: 204px"
    ]

    (slack_button_style_tags + size_tags).join(";")
  end

  def slack_button_style_tags
    [
      "align-items: center",
      "color: #000000",
      "background-color: #ffffff",
      "border: 1px solid #dddddd",
      "border-radius: 4px",
      "display: inline-flex",
      "font-family: Lato, sans-serif",
      "font-weight: 600",
      "justify-content: center",
      "text-decoration: none"
    ]
  end
end
