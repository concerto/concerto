class Media < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true
  
  attachable

  # Setup accessible attributes for your model
  attr_accessible :key, :file, :file_type

  # Validations
  validates :file_type, :presence => true
  validates :file_size, :numericality => { :greater_than_or_equal_to => 0 }
  
  scope :original, where({:key => "original"})
end
