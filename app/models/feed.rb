class Feed < ActiveRecord::Base
  belongs_to :group
  has_many :submissions
  has_many :contents, :through => :submissions
  has_many :subscriptions, :dependent => :destroy

  #Scoped relations for content approval states
  has_many :approved_contents, :through => :submissions, :source => :content, :conditions => {"submissions.moderation_flag" => true}
  has_many :pending_contents, :through => :submissions, :source => :content, :conditions => "submissions.moderation_flag IS NULL"
  has_many :denied_contents, :through => :submissions, :source => :content, :conditions => {"submissions.moderation_flag" => false}

  #Validations
  validates :name, :presence => true, :uniqueness => true
  validates :group, :presence => true, :associated => true
end
