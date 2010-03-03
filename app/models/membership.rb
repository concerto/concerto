class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  #Validations
  validates :user, :presence => true, :associated => true
  validates :group, :presence => true, :associated => true

  #Scoping shortcuts for leaders/regular
  scope :leader, where(:is_leader => true)
  scope :regular, where(:is_leader => false)
end
