class Field < ActiveRecord::Base
  belongs_to :type
  has_many :subscriptions, :dependent => :destroy
  
  #Validations
  validates :name, :presence => true
end
