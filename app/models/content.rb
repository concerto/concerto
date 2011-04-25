class Content < ActiveRecord::Base
  belongs_to :user
  belongs_to :kind
  has_many :submissions, :dependent => :destroy
  has_many :feeds, :through => :submissions
  has_many :media, :as => :attachable
  
  accepts_nested_attributes_for :media
  accepts_nested_attributes_for :submissions

  #Validations
  validates :name, :presence => true
  #validates :kind, :presence => true, :associated => true
  validates :user, :presence => true, :associated => true

  #Easily query for active, expired, or future content
  scope :expired, where("end_time < :now", {:now => Time.now})
  scope :future, where("start_time > :now", {:now => Time.now})
  scope :active, where("(start_time IS NULL OR start_time < :now) AND (end_time IS NULL OR end_time > :now)", {:now => Time.now})
  
  #Scoped relations for feed approval states
  has_many :approved_feeds, :through => :submissions, :source => :feed, :conditions => {"submissions.moderation_flag" => true}
  has_many :pending_feeds, :through => :submissions, :source => :feed, :conditions => "submissions.moderation_flag IS NULL"
  has_many :denied_feeds, :through => :submissions, :source => :feed, :conditions => {"submissions.moderation_flag" => false}

  # Determine if content is active based on its start and end times.
  # Content is active if two conditions are met:
  # 1. Start date is before now, or nil.
  # 2. End date is after now, or nil.
  def is_active?
    (start_time.nil? || start_time < Time.now) && (end_time.nil? || end_time > Time.now)
  end

  # Setter for the start time.  If a hash is passed, convert that into a DateTime object and then a string.
  # Otherwise, just set it like normal.  This is a bit confusing due to the differences in how Ruby handles
  # times between 1.9.x and 1.8.x.
  def start_time=(_start_time)
    if _start_time.kind_of?(Hash)
      #write_attribute(:start_time, Time.parse("#{_start_time[:date]} #{_start_time[:time]}").to_s(:db))
      write_attribute(:start_time, DateTime.strptime("#{_start_time[:date]} #{_start_time[:time]}","%m/%d/%Y %l:%M %p").to_s(:db))
    else
      write_attribute(:start_time, _start_time)
    end
  end

  # See start_time=.
  def end_time=(_end_time)
    if _end_time.kind_of?(Hash)
      write_attribute(:end_time, DateTime.strptime("#{_end_time[:date]} #{_end_time[:time]}","%m/%d/%Y %l:%M %p").to_s(:db))
    else
      write_attribute(:end_time, _end_time)
    end
  end

end
