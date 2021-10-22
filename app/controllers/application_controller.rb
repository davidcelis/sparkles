class ApplicationController < ActionController::Base
  def current_user
    @current_user ||= User.find_by(id: cookies.signed[:user_id])
  end
  helper_method :current_user

  def authenticated?
    !!@current_user
  end
  helper_method :authenticated?
end
