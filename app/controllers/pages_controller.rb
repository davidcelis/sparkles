class PagesController < ApplicationController
  def welcome
    # If the user is already signed in, redirect them to their team leaderboard
    if authenticated?
      redirect_to team_stats_path(current_team.slack_id)
      return
    end

    # Otherwise, set up the proper state for installing Sparkles...
    @state = SecureRandom.urlsafe_base64
    cookies.encrypted[:state] = @state

    # ... or signing in.
    @nonce = SecureRandom.urlsafe_base64
    cookies.encrypted[:nonce] = @nonce
  end
end
