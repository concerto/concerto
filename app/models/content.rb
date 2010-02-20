class Content < ActiveRecord::Base
  belongs_to :user
  belongs_to :type

  #Validations
  validates :name, :presence => true
  validates :mime_type, :presence => true

  #Enable more validations when the models are flushed out.
  #validates :user, :associated => true
  #validates :type, :associated => true

  #Determine if content is active based on its start and end times.
  def is_active?
    (start_time.nil? || start_time < Time.now) && (end_time.nil? || end_time > Time.now)
  end

end
