class SetDefaultsForPosition < ActiveRecord::Migration
  def up
    change_column_default :positions, :top, 0
    change_column_default :positions, :left, 0
    change_column_default :positions, :bottom, 0
    change_column_default :positions, :right, 0
  end

  def down
  end
end
