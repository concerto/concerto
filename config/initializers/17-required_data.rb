Rails.logger.debug "Starting 17-required_data at #{Time.now.to_s}"

if ActiveRecord::Base.connection.table_exists?('kinds')
  if !Kind.any?
    Rails.logger.error('All kinds are missing, creating some.')
    ["Graphics", "Ticker", "Text", "Dynamic"].each do |kind|
      Kind.find_or_create_by_name kind
    end
  end
end

if ActiveRecord::Base.connection.table_exists?('fields') && ActiveRecord::Base.connection.table_exists?('kinds')
  # If there are no fields, create some.
  if !Field.any?
    Rails.logger.error('All fields are missing, creating some.')
    Kind.all.each do |kind|
      field = Field.find_or_create_by_name({:name => kind.name, :kind => Kind.where(:name => kind.name).first})
    end
    # The time is just a special text field.
    Field.find_or_create_by_name({:name => 'Time', :kind => Kind.where(:name => 'Text').first})
  end
end
