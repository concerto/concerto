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
  
  #Feed Hierachy
  belongs_to :parent, :class_name => "Feed"
  has_many :children, :class_name => "Feed", :foreign_key => "parent_id"
  scope :roots, where(:parent_id => nil)
  
  # Test if this feed is a root feed or not
  def is_root?
    parent_id.nil?
  end
  
  # Collect a list of parent feeds.
  # Each feed the monkey stops as he climbs
  # up the tree.
  # Compliments of DHH http://github.com/rails/acts_as_tree
  def ancestors
    node, nodes = self, []
    nodes << node = node.parent while node.parent
    nodes
  end  
  
  # Collect recursive list of child feeds.
  # Every feed the monkey could stop by as he
  # climbs down a tree.
  # Compliments of http://github.com/funkensturm/acts_as_category
  def descendants
    node, nodes = self, []
    node.children.each { |child|
      if !nodes.include?(child) #Try and stop any circular dependencies
        nodes += [child]
        nodes += child.descendants
      end
    } unless node.children.empty?
    nodes
  end
  
  # Figure out how deep in the tree
  # the current feed is.  0 = root
  def depth
    ancestors.count
  end
  
  # The group of feeds who share a common parent.
  def self_and_siblings
    parent ? parent.children : Feed.roots
  end

  # The set of feeds available to be subscribed to a (screen, field) pair.
  # [All feeds - currently subscribed]
  # TODO: Check permissions.
  def self.subscribable(screen, field)
    subscriptions = Subscription.where(:screen_id => screen, :field_id => field)
    current_feeds = subscriptions.collect{ |s| s.feed }
    Feed.all - current_feeds
  end  
end
