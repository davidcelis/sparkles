Slack::Events.configure do |config|
  config.signing_secret = Rails.application.credentials.dig(:slack, :signing_secret)
  config.signature_expires_in = 300
end

Slack::Web::Client.configure do |config|
  config.default_page_size = 1000
end
