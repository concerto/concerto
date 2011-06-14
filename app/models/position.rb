class Position < ActiveRecord::Base
  belongs_to :field
  belongs_to :template
  
  #Validations
  validates :field, :presence => true, :associated => true
  validates :right, :numericality => {:greater_than_or_equal_to => -1, :less_than_or_equal_to => 1}
  validates :left, :numericality => {:greater_than_or_equal_to => -1, :less_than_or_equal_to => 1}
  validates :top, :numericality => {:greater_than_or_equal_to => -1, :less_than_or_equal_to => 1}
  validates :bottom, :numericality => {:greater_than_or_equal_to => -1, :less_than_or_equal_to => 1}

  # Compute the width of the position block.
  # A Concerto-1 style attribute, figuring out
  # the total width of the element.
  def width
    right-left
  end

  # Enable the width to be set of a position.
  # The right is adjusted relative to the left.
  # A Concerto-1 style accessor, mainly used
  # for importing templates.
  def width=(size)
    self.right = left + size.to_f
  end

  # Enabling the height to be set for a position.
  # The bottom is adjusted relative to the top.
  # A Concerto-1 style accessor, mainly used
  # for importing templates.
  def height=(size)
    self.bottom = top + size.to_f
  end
  
  # Compute the height of the position block.
  # Another Concerto-1 style attribute, figuring out
  # the total height of the element.
  def height
    bottom-top
  end
end
