class Field < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :kind
  has_many :subscriptions, :dependent => :destroy
  has_many :positions
  
  # Validations
  validates :name, :presence => true
end
