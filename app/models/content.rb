class Content < ActiveRecord::Base
  belongs_to :user
  belongs_to :type
  has_many :submissions
  has_many :feeds, :through => :submissions

  #Validations
  validates :name, :presence => true
  validates :mime_type, :presence => true

  #Enable more validations when the models are flushed out.
  #validates :user, :associated => true
  #validates :type, :associated => true

  #Easily query for active, expired, or future content
  scope :expired, where("end_time < :now", {:now => Time.now})
  scope :future, where("start_time > :now", {:now => Time.now})
  scope :active, where("(start_time IS NULL OR start_time < :now) AND (end_time IS NULL OR end_time > :now)", {:now => Time.now})

  #Determine if content is active based on its start and end times.
  def is_active?
    (start_time.nil? || start_time < Time.now) && (end_time.nil? || end_time > Time.now)
  end

end
