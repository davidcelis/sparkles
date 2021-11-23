module AuthenticationHelpers
  def sign_in(user)
    cookies[:slack_team_id] = user.slack_team_id
    cookies[:slack_user_id] = user.slack_id
  end

  def sign_out
    cookies.delete(:slack_team_id)
    cookies.delete(:slack_user_id)
  end
end
