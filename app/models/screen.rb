class Screen < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :owner, :polymorphic => true
  belongs_to :template
  has_many :subscriptions, :dependent => :destroy
  has_many :positions, :through => :template
  has_many :fields, :through => :positions

  # Validations
  validates :name, :presence => true
  validates :template, :presence => true, :associated => true
  #These two validations are used to solve problems with the polymorphic 
  #presence and associated tests.
  validates :owner_id, :presence => true
  validates_inclusion_of :owner_type, :in => %w( User Group )
  #The below validation fails loudly if the owner_type isn't a valid class
  #For now, the check will be string based, it should probably be moved to
  #something like if owner_type.is_class (however that would work)
  validates :owner, :presence => true, :associated => true, :if => Proc.new { ["User", "Group"].include?(owner_type) }

  #Newsfeed
  include PublicActivity::Common  
 
  # Scopes
  ONLINE_THRESHOLD = 5.minutes
  OFFLINE_THRESHOLD = 5.minutes
  scope :online, lambda { where('frontend_updated_at >= ?', Clock.time - Screen::ONLINE_THRESHOLD) }
  scope :offline, lambda { where('frontend_updated_at IS NULL OR frontend_updated_at < ?', Clock.time - Screen::OFFLINE_THRESHOLD) }

  # types of entities that may "own" a screen
  SCREEN_OWNER_TYPES = ["User", "Group"]
  
  # Determine the screen's aspect ratio.  If it doesn't exist, calculate it
  def aspect_ratio
    if width.nil? || height.nil?
      return { :width=> "", :height=> "" }
    end
    gcd = gcd(width,height)
    aspect_width = width/gcd
    aspect_height = height/gcd
    return {:width => aspect_width, :height => aspect_height }
  end

  # Run Euclidean algorithm to find GCD
  def gcd (a,b)
    if b == 0
      return a
    end
    return gcd(b, a.modulo(b))
  end

  def mark_updated
    update_column(:frontend_updated_at, Clock.time)
  end

  # Mark the screen as updated some percentage of the time.
  # Doesn't always mark the screen as updated to avoid flooding the database
  # but does it frequently enought for online / offline detection.
  def sometimes_mark_updated(pct=0.1)
    mark_updated if rand() <= pct
  end
end

