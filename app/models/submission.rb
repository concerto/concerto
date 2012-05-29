class Submission < ActiveRecord::Base
  belongs_to :content
  belongs_to :feed
  belongs_to :moderator, :class_name => "User"

  #Validations
  validates :feed, :presence => true, :associated => true
  validates :content, :presence => true, :associated => true
  validates :moderator, :presence => { :unless => :is_pending? }, :associated => true
  validates :duration, :numericality => { :greater_than => 0 }
  validates_uniqueness_of :content_id, :scope => :feed_id  #Enforce content can only be submitted to a feed once

  #Scoping shortcuts for active/denied/pending
  scope :approved, where(:moderation_flag => true)
  scope :denied, where(:moderation_flag => false)
  scope :pending, where("moderation_flag IS NULL")

  # Test if the submission has been approved.
  # (moderation flag is true)
  def is_approved?
    moderation_flag ? true : false
  end

  # Test if the submission has been denied.
  # (moderation flag is false)
  def is_denied?
    (moderation_flag == false) ? true : false
  end

  # Test if the submission has not yet been moderated.
  # (moderation flag is nil)
  def is_pending?
    moderation_flag.nil?
  end
end
