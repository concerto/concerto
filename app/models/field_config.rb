# frozen_string_literal: true

class FieldConfig < ApplicationRecord
  belongs_to :screen
  belongs_to :field
  belongs_to :pinned_content, class_name: "Content", optional: true

  validates :screen_id, uniqueness: { scope: :field_id, message: "already has a config for this field" }
  validates :ordering_strategy, inclusion: { in: ContentOrderers::STRATEGIES.keys }, allow_blank: true

  # A config whose field is not in the screen's current template is simply
  # inert: nothing renders it (see Frontend::ContentController and the screen
  # show page, which only look up configs for fields the template lays out).
  # We deliberately keep such "orphaned" configs rather than validating them
  # away, so that switching a screen's template back and forth (e.g. to a
  # seasonal layout and back) preserves the owner's pinned content and
  # ordering for each template's fields.
end
