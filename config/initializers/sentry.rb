Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Don't use Sentry for performance monitoring; stick to errors.
  config.traces_sample_rate = 0

  # Capture request bodies; ours don't actually contain any PII.
  config.send_default_pii = true
end
