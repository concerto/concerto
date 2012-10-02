class AddNarrativeTextToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :narrative, :text
  end
end
