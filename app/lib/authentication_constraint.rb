class AuthenticationConstraint
  def self.matches?(request)
    slack_team_id = request.cookie_jar.encrypted[:slack_team_id]
    slack_user_id = request.cookie_jar.encrypted[:slack_user_id]

    User.exists?(slack_team_id: slack_team_id, slack_id: slack_user_id)
  end
end
