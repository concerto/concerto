class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_settings_exist, only: [ :settings, :update_settings ]
  after_action :verify_authorized

  def settings
    authorize Setting, :index?
    @settings = Setting.where(key: Setting.defined_keys).index_by(&:key)
  end

  def update_settings
    authorize Setting, :update?

    setting_params.each do |key, value|
      setting = Setting.find_by(key: key)
      next if setting&.value_type == "secret" && value.blank?
      Setting[key] = value
    end
    redirect_to admin_settings_path, notice: "Settings were successfully updated."
  end

  private

  def ensure_settings_exist
    Setting.ensure_defaults_exist
  end

  def setting_params
    params.require(:settings).permit(Setting.defined_keys)
  end
end
