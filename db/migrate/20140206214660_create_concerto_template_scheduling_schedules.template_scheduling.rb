# This migration comes from template_scheduling (originally 20140118205731)
class CreateConcertoTemplateSchedulingSchedules < ActiveRecord::Migration
  def change
    create_table :concerto_template_scheduling_schedules do |t|
      t.integer :screen_id
      t.integer :template_id
      t.datetime :start_time
      t.datetime :end_time
      t.text :data

      t.timestamps
    end
  end
end
