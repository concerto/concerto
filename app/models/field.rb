class Field < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :kind
  has_many :subscriptions, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  has_many :field_configs, :dependent => :destroy
  #has_many :screens, :through => :field_configs   # valid, but not used yet
  
  attr_accessor  :config  # for setup.json formatting

  # Validations
  validates :name, :presence => true
  validates :kind_id, :presence => true
end
