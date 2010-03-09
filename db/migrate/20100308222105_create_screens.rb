class CreateScreens < ActiveRecord::Migration
  def self.up
    create_table :screens do |t|
      t.string :name
      t.string :location
      t.boolean :is_public
      t.references :owner, :polymorphic => true
      t.references :template

      t.timestamps
    end
  end

  def self.down
    drop_table :screens
  end
end
