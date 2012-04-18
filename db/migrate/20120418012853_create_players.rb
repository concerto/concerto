class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :secret
      t.string :ip_address
      t.integer :screen_id
      t.boolean :activated

      t.timestamps
    end
  end
end
