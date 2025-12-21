# frozen_string_literal: true

class FieldConfig < ApplicationRecord
  belongs_to :screen
  belongs_to :field
  belongs_to :pinned_content, class_name: "Content", optional: true

  validates :screen_id, uniqueness: { scope: :field_id, message: "already has a config for this field" }
  validate :field_belongs_to_template

  private

  def field_belongs_to_template
    return unless screen&.template && field

    unless screen.template.positions.exists?(field_id: field.id)
      errors.add(:field, "does not belong to the screen's template")
    end
  end
end
