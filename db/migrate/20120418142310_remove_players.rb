class RemovePlayers < ActiveRecord::Migration
  def up
    drop_table :players
  end

  def down
  end
end
