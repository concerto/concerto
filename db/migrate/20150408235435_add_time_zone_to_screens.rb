class AddTimeZoneToScreens < ActiveRecord::Migration
  def change
    rename_column :screens, :locale, :time_zone
    remove_column :screens, :height
    remove_column :screens, :width
  end
end
