class AdminController < ApplicationController
  def settings
    @settings = Setting.all.group_by { |s| s.key.split("_").first }
  end

  def update_settings
    setting_params.each do |key, value|
      Setting[key] = value
    end
    redirect_to admin_settings_path, notice: "Settings were successfully updated."
  end

  private

  def setting_params
    params.require(:settings).permit!
  end
end
