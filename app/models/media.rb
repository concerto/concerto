class Media < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :attachable, :polymorphic => true

  attachable

  PREVIEW_MEDIA_VALID_MINS = 3
  PREVIEW_MEDIA_PURGE_MINS = 15

  # Validations
  validates :file_type, :presence => true
  validates :file_size, :numericality => {:greater_than_or_equal_to => 0}

  scope :original, -> { where :key => "original" }
  scope :processed, -> { where :key => "processed" }
  scope :preview, -> { where :key => "preview" }
  scope :preferred, -> { where(:key => ["original", "processed"]).order("media.key desc") } # processed before original

  # remove preview records that have been abandoned
  def self.cleanup_previews
    Media.where("media.key = 'preview' and created_at < ?", PREVIEW_MEDIA_PURGE_MINS.minutes.ago).each do |r|
      r.destroy
    end
  end

  # Find a valid preview, if one exists, for a media id.
  # Here we enforce that the media is actually a preview and has been recently uploaded.
  def self.valid_preview(id)
    Media.where(:key => 'preview', :id => id, :attachable_id => 0).where('created_at > ?', PREVIEW_MEDIA_VALID_MINS.minutes.ago).first 
  end
end
