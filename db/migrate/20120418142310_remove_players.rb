class RemovePlayers < ActiveRecord::Migration
  def up
    drop_table :players
  end

  def down
    create_table :players do |t|
      t.string :secret
      t.string :ip_address
      t.integer :screen_id
      t.boolean :activated

      t.timestamps
    end
  end
end
