class Submission < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :content, :autosave => true
  belongs_to :feed
  belongs_to :moderator, :class_name => "User"

  after_save :update_children_moderation_flag

  # Validations
  validates :feed, :presence => true, :associated => true
  validates :content, :presence => true, :associated => true
  validates :moderator, :presence => { :unless => Proc.new { |s| s.is_pending? || s.content.is_expired? }}, :associated => true
  validates :duration, :numericality => { :greater_than => 0 }
  validates_uniqueness_of :content_id, :scope => :feed_id  #Enforce content can only be submitted to a feed once

  # Scoping shortcuts for approved/denied/pending
  scope :approved, where(:moderation_flag => true)
  scope :denied, where(:moderation_flag => false)
  scope :pending, where("moderation_flag IS NULL")

  # Scoping shortcuts for active/expired/future
  scope :active, joins(:content).merge(Content.active)
  scope :expired, joins(:content).merge(Content.expired)
  scope :future, joins(:content).merge(Content.future)
  
  #Newsfeed
  include PublicActivity::Common if defined? PublicActivity::Common

  def moderation_text
    case self.moderation_flag
      when true
        return "#{t(:approved)}"
      when false
        return "#{t(:rejected)}"
      when nil
        return "#{t(:pending)}"
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

  # Deny content which has previously expired.
  # Any submission belonging to content which has expired but has not yet been
  # reviewed is denied here.  We made a special exception to validations to allow
  # submissions to not have a moderator_id if the content has expired.
  def self.deny_old_expired
    Submission.pending.expired.readonly(false).each do |submission|
      submission.moderation_flag = false
      submission.moderation_reason = '#{t(:content_expired_mod)}'
      #Rails.logger.info submission
      #print submission.to_yaml
      #print submission.errors.to_yaml
      submission.save
    end    
  end

end
