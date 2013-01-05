class DynamicContent < Content
  after_initialize :set_kind, :create_config

  after_find :load_config
  before_validation :save_config

  attr_accessor :config

  # Automatically set the kind for the content
  # if it is new.  We use this hidden type that no fields
  # render so Dynamic Content meta content never gets displayed.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(:name => 'Dynamic').first
  end

  # Create a new configuration hash if necessary.
  def create_config
    self.config = self.config || {}
  end

  # Load a configuration hash back from the database to attribute.
  def load_config
    self.config = JSON.load(self.data)
  end

  # Prepare the configuration to be saved.
  def save_config
    self.data = JSON.dump(self.config)
  end
end
