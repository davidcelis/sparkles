class PagesController < ApplicationController
  def index
    # Set up the proper state for installing Sparkles.
    @state = SecureRandom.urlsafe_base64
    cookies.encrypted[:state] = @state
  end

  def terms
  end

  def privacy
  end
end
