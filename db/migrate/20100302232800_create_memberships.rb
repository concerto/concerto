class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.references :user
      t.references :group
      t.boolean :is_leader

      t.timestamps
    end
  end

  def self.down
    drop_table :memberships
  end
end
