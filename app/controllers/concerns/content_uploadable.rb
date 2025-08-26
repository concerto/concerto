module ContentUploadable
  extend ActiveSupport::Concern

  included do
    before_action :set_eligible_feeds, only: [ :new, :edit, :create, :update ]
  end

  private

  # Set feeds that can be assigned to content.
  def set_eligible_feeds
    @eligible_feeds = Feed.all
  end
end
