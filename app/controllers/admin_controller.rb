class AdminController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def settings
    # Authorize viewing settings (system admin only)
    authorize Setting, :index?
    @settings = Setting.all.group_by { |s| s.key.split("_").first }
  end

  def update_settings
    # Authorize that the user can update settings
    authorize Setting, :update?

    setting_params.each do |key, value|
      Setting[key] = value
    end
    redirect_to admin_settings_path, notice: "Settings were successfully updated."
  end

  private

  def setting_params
    # Only permit known setting keys to prevent mass assignment vulnerabilities
    params.require(:settings).permit(Setting.pluck(:key))
  end
end
