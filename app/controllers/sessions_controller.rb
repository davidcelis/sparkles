class SessionsController < ApplicationController
  def destroy
    cookies.clear

    redirect_to root_path
  end
end
