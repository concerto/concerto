class Submission < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :content, :autosave => true
  belongs_to :feed
  belongs_to :moderator, :class_name => "User"

  after_save :update_children_moderation_flag

  # Validations
  validates :feed, :presence => true, :associated => true
  validates :content, :presence => true, :associated => true
  validates :moderator, :presence => { :unless => :is_pending? }, :associated => true
  validates :duration, :numericality => { :greater_than => 0 }
  validates_uniqueness_of :content_id, :scope => :feed_id  #Enforce content can only be submitted to a feed once

  # Scoping shortcuts for approved/denied/pending
  scope :approved, -> { where :moderation_flag => true }
  scope :denied, -> { where :moderation_flag => false }
  scope :pending, -> { where "moderation_flag IS NULL" }

  # Scoping shortcuts for active/expired/future
  scope :active, -> { where joins(:content).merge(Content.active) }
  scope :expired, -> { where joins(:content).merge(Content.expired) }
  scope :future, -> { where joins(:content).merge(Content.future) }
  
  #Newsfeed
  include PublicActivity::Common if defined? PublicActivity::Common

  def moderation_text
    case self.moderation_flag
      when true
        return "Approved"
      when false
        return "Rejected"
      when nil
        return "Pending"                
      end  
  end

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

  # Cascade moderation to children submissions as well.
  # Child content submitted to the same feed will recieve the same moderation
  # as a parent content.
  def update_children_moderation_flag
    if self.changed.include?('moderation_flag') and self.content.has_children?
      self.content.children.each do |child|
        similiar_submissions = Submission.where(:content_id => child.id, :feed_id => self.feed_id, :moderation_flag => self.moderation_flag_was)
        similiar_submissions.each do |child_submission|
          child_submission.update_attributes({:moderation_flag => self.moderation_flag, :moderator_id => self.moderator_id})
        end
      end
    end
  end
end
