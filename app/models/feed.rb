class Feed < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :group
  has_many :submissions, dependent: :destroy
  has_many :contents, through: :submissions
  has_many :subscriptions, dependent: :destroy
  serialize :content_types, Hash

  # Scoped relations for content approval states
  has_many :approved_contents, -> { where "submissions.moderation_flag" => true}, through: :submissions, source: :content
  has_many :pending_contents, -> { where "submissions.moderation_flag IS NULL"}, through: :submissions, source: :content
  has_many :denied_contents, -> { where "submissions.moderation_flag" => false}, through: :submissions, source: :content

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :group, presence: true, associated: true
  validate :parent_id_cannot_be_this_feed

  #Newsfeed
  include PublicActivity::Common if defined? PublicActivity::Common

  # Generate a unique list of screens on which this feed appears
  def shown_on_screens
    return subscriptions.collect{|s| s.screen }.uniq
  end

  def parent_id_cannot_be_this_feed
    if !parent_id.blank? and parent_id == id
      errors.add(:parent_id, I18n.t(:cant_be_this_feed))
    end
  end

  # Feed Hierarchy
  belongs_to :parent, class_name: "Feed"
  has_many :children, class_name: "Feed", foreign_key: "parent_id"

  default_scope { order 'LOWER(feeds.name)' }
  scope :roots, -> { where parent_id: nil }

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
  # [All accessible feeds - currently subscribed]
  def self.subscribable(screen, field)
    subscriptions = Subscription.where(screen_id: screen, field_id: field)
    current_feeds = subscriptions.collect{ |s| s.feed }

    accessible_feeds = Feed.accessible_by(Ability.new(screen), :read)
    accessible_feeds - current_feeds
  end

  # Figure out which submissions need to be moderated.
  # This is a list of all the pending submissions minus dynamic content who have
  # a parent pending moderation (since that moderation will propogate automatically).
  def submissions_to_moderate
    moderate = self.submissions.pending.to_a
    moderate_content = moderate.collect{|s| s.content}
    moderate.reject! do |s|
      !s.content.parent.nil? && moderate_content.include?(s.content.parent)
    end
    return moderate
  end
end
