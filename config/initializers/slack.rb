module Slack
  CLIENT_ID = ENV.fetch("SLACK_CLIENT_ID") { Rails.application.credentials.dig(:slack, :client_id) }
  CLIENT_SECRET = ENV.fetch("SLACK_CLIENT_SECRET") { Rails.application.credentials.dig(:slack, :client_secret) }
  SIGNING_SECRET = ENV.fetch("SLACK_SIGNING_SECRET") { Rails.application.credentials.dig(:slack, :signing_secret) }
end

Slack::Events.configure do |config|
  config.signing_secret = Slack::SIGNING_SECRET
  config.signature_expires_in = 300
end

Slack::Web::Client.configure do |config|
  config.default_page_size = 1000
end
