class Field < ActiveRecord::Base
  belongs_to :kind
  has_many :subscriptions, :dependent => :destroy
  has_many :positions

  # Setup accessible attributes for your model
  attr_accessible :name, :kind_id

  # Validations
  validates :name, :presence => true
end
