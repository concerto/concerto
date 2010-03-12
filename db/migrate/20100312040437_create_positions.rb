class CreatePositions < ActiveRecord::Migration
  def self.up
    create_table :positions do |t|
      t.text :style
      t.decimal :top, :precision => 6, :scale => 5
      t.decimal :left, :precision => 6, :scale => 5
      t.decimal :bottom, :precision => 6, :scale => 5
      t.decimal :right, :precision => 6, :scale => 5
      t.references :field
      t.references :template

      t.timestamps
    end
  end

  def self.down
    drop_table :positions
  end
end
