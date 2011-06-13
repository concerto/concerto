# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Populate the 3 major 'kinds' of content we know as of now.
# There is discussion to move this to a static array / config elsewhere,
# but I don't have a solid grasp on the system-wide reprecussions of that
# change at the moment.
kinds = Kind.create([{:name => 'Graphics'}, {:name => 'Ticker'}, {:name => 'Text'}])

# Establish the 4 major display areas a template usually has.
# In my quick sample, this code will make 68% of the Concerto 1 fields match
# up correct with the new Concerto 2 fields.  Magic will have to handle the other
# 42% of fields with stranger names like "Graphics (Full-Screen)"
kinds.each do |kind|
  # We use a verbose (and ineffecient) query to find the type
  # because the create statement doesn't garuntee success,
  # in that case we'll hope a duplicate existed and blocked the validation.
  field = Field.create({:name => kind.name, :kind => Kind.where(:name => kind.name).first})
end
# The time is just a special text field.
Field.create({:name => 'Time', :kind => Kind.where(:name => 'Text').first})
