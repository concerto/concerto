class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  #Validations
  validates :user, :presence => true, :associated => true
  validates :group, :presence => true, :associated => true
  validates_uniqueness_of :user_id, :scope => :group_id

  #Scoping shortcuts for leaders/regular
  scope :leader, where(:is_leader => true)
  scope :regular, where(:is_leader => false)
end
