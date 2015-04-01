Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

if ActiveRecord::Base.connection.table_exists?('kinds')
  if !Kind.any?
    Rails.logger.error('All kinds are missing, creating some.')
    ["Graphics", "Ticker", "Text", "Dynamic"].each do |kind|
      Kind.where(name: kind).first_or_create
    end
  end
end

if ActiveRecord::Base.connection.table_exists?('fields') && ActiveRecord::Base.connection.table_exists?('kinds')
  # If there are no fields, create some.
  if !Field.any?
    Rails.logger.error('All fields are missing, creating some.')
    Kind.all.each do |kind|
      field = Field.where(name: kind.name).first_or_create(kind: Kind.where(name: kind.name).first)
    end
    # The time is just a special text field.
    Field.where(name: 'Time').first_or_create(kind: Kind.where(name: 'Text').first)
  end
end

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"
