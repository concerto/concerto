class FeedPolicy < ApplicationPolicy
  include GroupManagedPolicy

  def index?
    true
  end

  def show?
    true
  end

  def new?
    super || can_create_new?
  end

  def create?
    super || can_create?
  end

  def edit?
    super || can_edit?
  end

  def update?
    super || can_update?
  end

  def destroy?
    super || can_destroy?
  end

  def refresh?
    update?
  end

  def cleanup?
    update?
  end

  private

  # :type and :config are deliberately absent. Changing type would let a
  # group member turn a feed into an auto-approving RssFeed/RemoteFeed (or an
  # unknown class that breaks every page loading feeds), and config holds
  # subclass settings that each controller permits by name.
  def entity_specific_attributes
    [ :name, :description ]
  end
end
