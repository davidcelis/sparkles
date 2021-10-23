class AuthenticationConstraint
  def self.matches?(request)
    team_id = request.cookie_jar.encrypted[:team_id]
    user_id = request.cookie_jar.encrypted[:user_id]

    User.exists?(id: user_id, team_id: team_id)
  end
end
