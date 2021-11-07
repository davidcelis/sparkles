class ApplicationController < ActionController::Base
  def current_user
    @current_user ||= User.find_by(
      slack_team_id: cookies.encrypted[:slack_team_id],
      slack_id: cookies.encrypted[:slack_user_id]
    )
  end
  helper_method :current_user

  def current_team
    return unless authenticated?

    @current_team ||= current_user.team
  end
  helper_method :current_team

  def authenticated?
    !!current_user
  end
  helper_method :authenticated?

  def leaderboard_enabled?
    return unless authenticated?

    current_team.leaderboard_enabled? && current_user.leaderboard_enabled?
  end
  helper_method :leaderboard_enabled?

  def require_authentication
    redirect_to sign_in_path unless authenticated?
  end
end
