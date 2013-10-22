#Key-value store for field-specific configurations
class FieldConfig < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  belongs_to :field
  belongs_to :screen

  validates_presence_of :key, :field_id, :screen_id
  validates_uniqueness_of :key, :scope => [:screen_id, :field_id]

  def self.get(screen, field, key)
    field_config = FieldConfig.where(:screen_id => screen.id, :field_id => field.id, :key => key).first
    if !field_config.nil?
      return field_config.value
    else
      return nil
    end
  end    
end

