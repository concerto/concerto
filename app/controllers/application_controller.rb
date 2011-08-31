class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_locale
  
  def set_locale
    if user_signed_in? && current_user.locale != ""
      session[:locale] = current_user.locale
    end

    I18n.locale = session[:locale] || I18n.default_locale
  end
end
