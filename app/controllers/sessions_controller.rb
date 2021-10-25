class SessionsController < ApplicationController
  def new
    @state = SecureRandom.urlsafe_base64
    cookies.encrypted[:state] = @state

    @nonce = SecureRandom.urlsafe_base64
    cookies.encrypted[:nonce] = @nonce
  end

  def destroy
    cookies.clear

    redirect_to sign_in_path
  end
end
