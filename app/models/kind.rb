class Kind < ActiveRecord::Base
  has_many :contents
  has_many :fields

  # Setup accessible attributes for your model
  attr_accessible :name

  # Validations
  validates :name, :presence => true, :uniqueness => true
end
