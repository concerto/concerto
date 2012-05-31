class DefaultTemplateToPublic < ActiveRecord::Migration
  def up
    change_column_default :templates, :is_hidden, false
  end

  def down
    change_column_default :templates, :is_hidden, nil
  end
end
