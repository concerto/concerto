class Screen < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # Allow screens to act as accessors for the Frontend API
  #devise

  belongs_to :owner, :polymorphic => true
  belongs_to :template
  has_many :subscriptions, :dependent => :destroy
  has_many :positions, :through => :template
  has_many :fields, :through => :positions

  # Validations
  validates :name, :presence => true, :uniqueness => true
  validates :template, :presence => true, :associated => true
  #These two validations are used to solve problems with the polymorphic 
  #presence and associated tests.
  validates :owner_id, :presence => true
  validates_inclusion_of :owner_type, :in => %w( User Group )
  #The below validation fails loudly if the owner_type isn't a valid class
  #For now, the check will be string based, it should probably be moved to
  #something like if owner_type.is_class (however that would work)
  validates :owner, :presence => true, :associated => true, :if => Proc.new { ["User", "Group"].include?(owner_type) }
  # Authentication token must be unique, prevents mac address collisions with legacy screens.
  validates :authentication_token, :uniqueness => {:allow_nil => true}

  #Newsfeed
  include PublicActivity::Common if defined? PublicActivity::Common
 
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

  def is_online?
    !frontend_updated_at.nil? && frontend_updated_at >= (Clock.time - Screen::ONLINE_THRESHOLD)
  end

  def is_offline?
    frontend_updated_at.nil? || frontend_updated_at < (Clock.time - Screen::OFFLINE_THRESHOLD)
  end

  def self.find_by_mac(mac_addr)
    begin
      mac = MacAddr::condense(mac_addr)
      token = "mac:#{mac}"
      screen = Screen.where(:authentication_token => token).first
      return screen
    rescue ActiveRecord::ActiveRecordError
      return nil
    end
  end

  def mac_address=(mac_addr)
    mac = MacAddr::condense(mac_addr)
    if !mac.empty?
      self.authentication_token = "mac:#{mac}"
    else
      self.authentication_token = nil
    end
  end

  def mac_address
    mac = token_by_type('mac')
    mac = MacAddr::expand(mac) unless mac.nil?
    return mac
  end

  def screen_token
    token_by_type('auth')
  end

  def self.find_by_screen_token(token)
    return nil if token.blank?
    begin
      Screen.where(:authentication_token=>'auth:'+token).first
    rescue ActiveRecord::ActiveRecordError
      nil
    end
  end 

  def generate_screen_token!
    require 'securerandom'
    token = SecureRandom.hex
    self.update_attribute(:authentication_token, 'auth:'+token)
    return token
  end

  def clear_screen_token!
    self.update_attribute(:authentication_token, '')
  end

  # The token is first associated with a session, not a Screen, so
  # it is generated independent of a particular instance
  def self.generate_temp_token
    require 'securerandom'
    token = SecureRandom.hex(3) # Short token (length 3*2) since the user will enter this
    return token
  end

  def self.find_by_temp_token(token)
    return nil if token.blank?
    begin
      Screen.where(:authentication_token=>'temp:'+token).first
    rescue ActiveRecord::ActiveRecordError
      nil
    end
  end

private

  # Right now there are three types of tokens
  #   mac -  for public screens that are accessed by legacy clients
  #   auth - for authenticating secure screens once they are set up
  #   temp - used during one-time setup for secure screens
  def token_by_type(type)
    return nil if self.authentication_token.nil?
    (token_type, value) = self.authentication_token.split(':')
    return value if type == token_type
    return nil
  end
end

