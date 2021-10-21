Slack::Events.configure do |config|
  config.signing_secret = Rails.application.credentials.dig(:slack, :signing_secret)
  config.signature_expires_in = 300
end
