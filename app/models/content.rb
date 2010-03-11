class Content < ActiveRecord::Base
  belongs_to :user
  belongs_to :type
  has_many :submissions, :dependent => :destroy
  has_many :feeds, :through => :submissions
  has_many :medias, :as => :attachable
  
  accepts_nested_attributes_for :medias
  accepts_nested_attributes_for :submissions

  #Validations
  validates :name, :presence => true
  validates :mime_type, :presence => true
  validates :type, :presence => true, :associated => true
  validates :user, :presence => true, :associated => true


  #Easily query for active, expired, or future content
  scope :expired, where("end_time < :now", {:now => Time.now})
  scope :future, where("start_time > :now", {:now => Time.now})
  scope :active, where("(start_time IS NULL OR start_time < :now) AND (end_time IS NULL OR end_time > :now)", {:now => Time.now})
  
  #Scoped relations for feed approval states
  has_many :approved_feeds, :through => :submissions, :source => :feed, :conditions => {"submissions.moderation_flag" => true}
  has_many :pending_feeds, :through => :submissions, :source => :feed, :conditions => "submissions.moderation_flag IS NULL"
  has_many :denied_feeds, :through => :submissions, :source => :feed, :conditions => {"submissions.moderation_flag" => false}

  #Determine if content is active based on its start and end times.
  def is_active?
    (start_time.nil? || start_time < Time.now) && (end_time.nil? || end_time > Time.now)
  end

end
