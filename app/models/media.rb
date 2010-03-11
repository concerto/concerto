class Media < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true
  
  attachable
  
  scope :original, where({:key => "original"})
end
