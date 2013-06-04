class Frontend::ScreenAuthController < ApplicationController
  before_filter :screen_api
  # GET /frontend/
  # Entry point for secure screens.
  # If a screen is logged in or credentials are present, redirect
  # to the proper frontend address for the current screen. Otherwise,
  # prompt for manual authentication / configuration by an admin.
  # 
  # Dummy credential system:
  #   GET /frontend/screen_id=4 to sign in as screen 4
  #   GET /frontend/screen_id=  to sign out current screen
  #   GET /frontend/            to view current login stauts
  # TODO: Real Authentication
  def index
    if !params[:screen_id].nil?
      if !params[:screen_id].blank?
        screen = Screen.find(params[:screen_id])
        if screen.is_a?(Screen) 
          sign_in :screen, screen
          #current_screen.remember_me!
        end
      else
        sign_out :screen
      end
    end
  end
end
