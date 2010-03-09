class Screen < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  belongs_to :template

  #Validations
  validates :name, :presence => true
  #These two validations are used to solve problems with the polymorphic 
  #presence and associated tests.
  validates :owner_id, :presence => true
  validates_inclusion_of :owner_type, :in => %w( User Group )
  #The below validation fails loudly if the owner_type isn't a valid class
  #For now, the check will be string based, it should probably be moved to
  #something like if owner_type.is_class (however that would work)
  validates :owner, :presence => true, :associated => true, :if => Proc.new { ["User", "Group"].include?(owner_type) }

end
