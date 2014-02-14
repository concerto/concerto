class Kind < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_many :contents
  has_and_belongs_to_many :fields

  # Validations
  validates :name, :presence => true, :uniqueness => true
end
