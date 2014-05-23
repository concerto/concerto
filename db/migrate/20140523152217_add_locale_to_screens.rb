class AddLocaleToScreens < ActiveRecord::Migration
  def change
    add_column :screens, :locale, :string
  end
end
