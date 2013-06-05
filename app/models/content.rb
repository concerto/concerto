class Content < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  belongs_to :kind
  has_many :submissions, :dependent => :destroy, :after_add => :after_add_callback
  has_many :feeds, :through => :submissions
  has_many :media, :as => :attachable, :dependent => :destroy

  accepts_nested_attributes_for :media
  accepts_nested_attributes_for :submissions

  # Validations
  validates :name, :presence => true
  #validates :kind, :presence => true, :associated => true
  validates :user, :presence => true, :associated => true
  validate :parent_id_cannot_be_this_content

  def parent_id_cannot_be_this_content
    if !parent_id.blank? and parent_id == id
      errors.add(:parent_id, "can't be this content")
    end
  end

  #Newsfeed
  include PublicActivity::Common if defined? PublicActivity::Common

  belongs_to :parent, :class_name => "Content", :counter_cache => :children_count
  has_many :children, :class_name => "Content", :foreign_key => "parent_id"

  # By default, only find known content types.
  # This allows everything to keep working if a content type goes missing
  # or (more likely) gets removed.
  default_scope { where(:type => Content.all_subclasses.collect { |s| s.name }) unless Rails.env.development? }

  # Easily query for active, expired, or future content
  # The scopes are defined as class methods to delay their resolution, defining them as proper scopes
  # will break lots of things, see https://github.com/concerto/concerto/issues/288.
  def self.expired
    where("end_time < :now", {:now => Clock.time})
  end

  def self.future
    where("start_time > :now", {:now => Clock.time})
  end

  def self.active
    where("(start_time IS NULL OR start_time < :now) AND (end_time IS NULL OR end_time > :now)", {:now => Clock.time})
  end

  # Scoped relations for feed approval states
  has_many :approved_feeds, -> { where "submissions.moderation_flag" => true }, :through => :submissions, :source => :feed
  has_many :pending_feeds, -> { where "submissions.moderation_flag IS NULL" }, :through => :submissions, :source => :feed
  has_many :denied_feeds, -> { where "submissions.moderation_flag" => false }, :through => :submissions, :source => :feed

  # Magic to let us generate routes
  delegate :url_helpers, :to => 'Rails.application.routes'

  # Determine if content is active based on its start and end times.
  # Content is active if two conditions are met:
  # 1. Start date is before now, or nil.
  # 2. End date is after now, or nil.
  def is_active?
    (start_time.nil? || start_time < Clock.time) && (end_time.nil? || end_time > Clock.time)
  end

  # Determine if content is expired based on its end time.
  def is_expired?
    (end_time < Clock.time)
  end

  def is_orphan?
    self.submissions.empty?
  end

  # Determine if content is approved everywhere
  def is_approved?
    (self.approved_feeds.count > 0) && ((self.pending_feeds.count + self.denied_feeds.count) == 0)
  end

  # Determine if content is pending on a feed
  def is_pending?
    (self.pending_feeds.count > 0)
  end

  # Determine if content is denied on a feed
  def is_denied?
    (self.denied_feeds.count > 0)
  end

  # Setter for the start time.  If a hash is passed, convert that into a DateTime object and then a string.
  # Otherwise, just set it like normal.  This is a bit confusing due to the differences in how Ruby handles
  # times between 1.9.x and 1.8.x.
  def start_time=(_start_time)
    if _start_time.kind_of?(Hash)
      #write_attribute(:start_time, Time.parse("#{_start_time[:date]} #{_start_time[:time]}").to_s(:db))
      write_attribute(:start_time, DateTime.strptime("#{_start_time[:date]} #{_start_time[:time]}", "%m/%d/%Y %l:%M %p").to_s(:db))
    else
      write_attribute(:start_time, _start_time)
    end
  end

  # See start_time=.
  def end_time=(_end_time)
    if _end_time.kind_of?(Hash)
      write_attribute(:end_time, DateTime.strptime("#{_end_time[:date]} #{_end_time[:time]}", "%m/%d/%Y %l:%M %p").to_s(:db))
    else
      write_attribute(:end_time, _end_time)
    end
  end


  # A placeholder for a pre-rendering processing trigger.
  def pre_render(*arg)
    true
  end

  # The additional data required when rendering this content.
  def render_details
    {:data => self.data}
  end

  # Allow the subclasses to render a preview of their content
  def self.preview(*arg)
    ""
  end

  # A quick test to see if a content has any children
  def has_children?
    !self.children.empty?
  end

  # Define the attributes that will be allowed via strong_parameters.
  # We define a common set of attribtues here, expecting child content types to
  # supplement this list with additional attributes that they require.
  def self.form_attributes
    attributes = [:name, :duration, :data, {:start_time => [:time, :date]}, {:end_time => [:time, :date]}]
  end

  # All the subclasses of Content.
  # Conduct a DFS walk of the Content class tree and return the results.
  # This is important because DynamicContent is always 1 step removed
  # from content (Content > DynamicContent > Rss).
  def self.all_subclasses
    sub = []
    sub.concat(self.subclasses)
    self.subclasses.each do |subklass|
      sub.concat(subklass.all_subclasses)
    end
    return sub
  end

  # Display the pretty name of the content type.
  def self.display_name
    if self.const_defined?("DISPLAY_NAME") && !self::DISPLAY_NAME.nil?
      self::DISPLAY_NAME
    else
      self.model_name.human
    end
  end

  # Figure out if a user should be able to run a custom action.
  # Default to any user runs no actions.
  def action_allowed?(action_name, user)
    return false
  end

  # Perform custom actions on a piece of content.
  # Accessed via /content/:id/act?action_name=action_name&options.
  # Returns nil if there was a problem, otherwise return the result of the action.
  def perform_action(action_name, options)
    if action_allowed?(action_name, options[:current_user])
      return send(action_name, options)
    else
      return nil
    end
  end

  # A placeholder for any action that should be performed
  # after content has been submitted to a feed.
  def after_add_callback(unused_submission)
  end

end
