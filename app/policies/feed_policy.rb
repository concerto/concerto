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

  # Returns attributes that are safe to display in the show view/json/index.
  # Base Feed's `config` carries nothing sensitive, so everything is shown.
  # Overridden by RemoteFeedPolicy and RssFeedPolicy, whose `config.url` can
  # carry a feed source URL with an embedded API key or token (CWE-200) --
  # see those policies' comments. `:url` is the gate every caller (the
  # per-type show views/jbuilders, and the generic feeds/_feed.json.jbuilder
  # partial used by both /feeds.json and /feeds/:id.json) checks before
  # including `config` at all.
  def permitted_attributes_for_show
    [ :id, :name, :description, :type, :group_id, :created_at, :updated_at, :url, :config ]
  end

  private

  def entity_specific_attributes
    [ :name, :description, :type, :config ]
  end
end
