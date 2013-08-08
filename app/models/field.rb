class Field < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :kind
  has_many :subscriptions, :dependent => :destroy
  has_many :positions
  has_many :field_configs, :dependent => :destroy
  #has_many :screens, :through => :field_configs   # valid, but not used yet
  
  alias_method :config, :field_configs  # for setup.json formatting

  # Validations
  validates :name, :presence => true
end
