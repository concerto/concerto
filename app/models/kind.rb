class Kind < ActiveRecord::Base
  has_many :contents
  has_many :fields

  # Setup accessible attributes for your model
  attr_accessible :name, :id, :created_at, :updated_at

  # Validations
  validates :name, :presence => true, :uniqueness => true
end
