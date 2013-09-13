class Media < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :attachable, :polymorphic => true
  
  attachable
  
  # Validations
  validates :file_type, :presence => true
  validates :file_size, :numericality => { :greater_than_or_equal_to => 0 }
  
  scope :original, where({:key => "original"})
  scope :processed, where({:key => "processed"})
  scope :preferred, where({:key => ["original", "processed"]}).order("media.key desc")   # processed before original

  # remove preview records that have been abandoned
  def self.cleanup_previews
    Media.where("media.key = 'preview' and created_at < ?", 15.minutes.ago).each do |r|
      r.destroy
    end
  end
end
