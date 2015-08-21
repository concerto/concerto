class ScreenTimeZone < ActiveRecord::Migration
  def change
    rename_column :screens, :locale, :time_zone
  end
end
