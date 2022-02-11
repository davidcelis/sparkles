source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.3"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 6.1.4", ">= 6.1.4.1"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use Puma as the app server
gem "puma", "~> 5.6"

# Use SCSS for stylesheets
gem "sass-rails", ">= 6"

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem "webpacker", "~> 5.0"

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"

# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false
gem "listen", "~> 3.3"

# Use the official API client to connect to Slack
gem "slack-ruby-client"
gem "jwt"
gem "slack_markdown"

# Use Sidekiq for background job processing
gem "sidekiq"
gem "sidekiq-scheduler"

# Paginate through sparkles and the leaderboard with Kaminari
gem "kaminari"

# Monitor performance and errors with Skylight and Sentry
gem "skylight"
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"

group :development, :test do
  # Call "binding.pry" anywhere in the code to stop execution and get a debugger console
  gem "pry-byebug"
  gem "pry-rails"

  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "mocktail"
  gem "standard"
  gem "vcr"
  gem "webmock"
end

group :development do
  # Access an interactive console on exception pages or by calling "console" anywhere in the code.
  gem "web-console", ">= 4.1.0"

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 2.0"

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
end
