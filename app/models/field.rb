class Field < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_and_belongs_to_many :kinds
  has_many :subscriptions, :dependent => :destroy
  has_many :positions
  has_many :field_configs, :dependent => :destroy
  #has_many :screens, :through => :field_configs   # valid, but not used yet
  
  attr_accessor  :config  # for setup.json formatting

  # Validations
  validates :name, :presence => true
end
