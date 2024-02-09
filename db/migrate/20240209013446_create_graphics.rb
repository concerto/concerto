class CreateGraphics < ActiveRecord::Migration[7.1]
  def change
    create_table :graphics do |t|
      t.timestamps
    end
  end
end
