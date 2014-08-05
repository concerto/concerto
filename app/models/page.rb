class Page < ActiveRecord::Base
  before_create :add_slug
  before_update :add_slug

  def add_slug
    self.slug = self.title.parameterize
  end

  def to_param
    slug
  end

end
