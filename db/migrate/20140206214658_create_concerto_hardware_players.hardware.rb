# This migration comes from hardware (originally 20121220000000)
class CreateConcertoHardwarePlayers < ActiveRecord::Migration
  def change
    create_table :concerto_hardware_players do |t|
      t.string :secret
      t.string :ip_address
      t.integer :screen_id
      t.boolean :activated

      t.timestamps
    end
  end
end
