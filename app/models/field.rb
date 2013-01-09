class Field < ActiveRecord::Base
  belongs_to :kind
  has_many :subscriptions, :dependent => :destroy
  has_many :positions
  
  # Validations
  validates :name, :presence => true
end
