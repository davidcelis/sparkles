class SessionsController < ApplicationController
  def new
    @state = SecureRandom.urlsafe_base64
    cookies.encrypted[:state] = @state

    @nonce = SecureRandom.urlsafe_base64
    cookies.encrypted[:nonce] = @nonce
  end
end
