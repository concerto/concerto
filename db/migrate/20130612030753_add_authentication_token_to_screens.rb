class AddAuthenticationTokenToScreens < ActiveRecord::Migration
  def change
    add_column :screens, :authentication_token, :string
  end
end
