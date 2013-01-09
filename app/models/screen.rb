class Screen < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  belongs_to :template
  has_many :subscriptions, :dependent => :destroy
  has_many :positions, :through => :template
  has_many :fields, :through => :positions

  # Setup accessible attributes for your model
  attr_accessible :name, :location, :width, :height, :is_public, :template_id, :id, :owner_id, :owner_type, :created_at, :updated_at

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
 
  # Scopes
  # THESE ARE MOCK INTERFACES.  PRETEND THEY MAKE SENSE.
  # TODO(bamnet): Make these real.
  scope :online, where(:is_public => true)
  scope :offline, where(:is_public => false)

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
end

