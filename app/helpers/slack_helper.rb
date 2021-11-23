module SlackHelper
  SLACK_OAUTH_URL = "https://slack.com/oauth/v2/authorize".freeze
  SLACK_OPENID_URL = "https://slack.com/openid/connect/authorize".freeze

  USER_PATTERN = /<@(?<slack_user_id>\w+)(?:\|[^>]*)?>/
  CHANNEL_PATTERN = /<#(?<slack_channel_id>\w+)(?:\|[^>]*)?>/
  EMOJI_PATTERN = /:([^:\s]*(?:::[^:\s]*)*):/
  STOCK_EMOJI_NAMES = Emoji.all.flat_map(&:aliases).freeze

  BOT_SCOPES = [
    "channels:history",
    "channels:join",
    "channels:read",
    "chat:write",
    "commands",
    "emoji:read",
    "groups:history",
    "groups:read",
    "reactions:read",
    "team:read",
    "users.profile:read",
    "users:read"
  ].freeze

  USER_SCOPES = ["openid"].freeze

  def sign_in_with_slack_button(state:, nonce:)
    authorization_url = URI(SLACK_OPENID_URL)
    authorization_url.query = {
      response_type: :code,
      scope: USER_SCOPES.join(","),
      client_id: Slack::CLIENT_ID,
      state: state,
      nonce: nonce,
      redirect_uri: slack_openid_callback_url
    }.to_query

    link_to authorization_url.to_s do
      image_tag("https://platform.slack-edge.com/img/sign_in_with_slack.png", height: 40, width: 170, srcset: {"https://platform.slack-edge.com/img/sign_in_with_slack.png" => "1x", "https://platform.slack-edge.com/img/sign_in_with_slack@2x.png" => "2x"})
    end
  end

  def add_to_slack_button(state:)
    authorization_url = URI(SLACK_OAUTH_URL)
    authorization_url.query = {
      scope: BOT_SCOPES.join(","),
      user_scope: USER_SCOPES.join(","),
      client_id: Slack::CLIENT_ID,
      state: state,
      redirect_uri: slack_oauth_callback_url
    }.to_query

    link_to authorization_url.to_s do
      image_tag("https://platform.slack-edge.com/img/add_to_slack.png", height: 40, width: 139, srcset: {"https://platform.slack-edge.com/img/add_to_slack.png" => "1x", "https://platform.slack-edge.com/img/add_to_slack@2x.png" => "2x"})
    end
  end
end
