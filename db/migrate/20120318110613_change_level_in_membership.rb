class ChangeLevelInMembership < ActiveRecord::Migration
  def up
    change_column :memberships, :level, :integer, default: 1
  end

  def down
    change_column :memberships, :level, :integer, default: 0
  end
end
