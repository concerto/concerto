class Type < ActiveRecord::Base
  has_many :contents

  #Validations
  validates :name, :presence => true, :uniqueness => true
end
