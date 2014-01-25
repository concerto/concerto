# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

#It's important to use find_or_create_by_{attribute} so as to prevent duplicate creation of records

# Populate the 3 major 'kinds' of content we know as of now.
# There is discussion to move this to a static array / config elsewhere,
# but I don't have a solid grasp on the system-wide reprecussions of that
# change at the moment.
# Note: This is replicated in config/initializers/17-required_data.rb because an instance must have kinds.
["Graphics", "Ticker", "Text", "Dynamic"].each do |kind|
  Kind.find_or_create_by_name kind
end

#Default plugins
ConcertoPlugin.find_or_create_by_gem_name({:gem_name => "concerto_weather", :enabled => true, :source => "rubygems"})
ConcertoPlugin.find_or_create_by_gem_name({:gem_name => "concerto_remote_video", :enabled => true, :source => "rubygems"})
ConcertoPlugin.find_or_create_by_gem_name({:gem_name => "concerto_simple_rss", :enabled => true, :source => "rubygems"})
ConcertoPlugin.find_or_create_by_gem_name({:gem_name => "concerto_iframe", :enabled => true, :source => "rubygems"})
ConcertoPlugin.find_or_create_by_gem_name({:gem_name => "concerto_calendar", :enabled => true, :source => "rubygems"})
ConcertoPlugin.find_or_create_by_gem_name({:gem_name => "concerto-hardware", :enabled => false, :source => "rubygems"})
ConcertoPlugin.find_or_create_by_gem_name({:gem_name => "concerto_audio", :enabled => false, :source => "rubygems"})
ConcertoPlugin.find_or_create_by_gem_name({:gem_name => "concerto_template_scheduling", :enabled => false, :source => "rubygems"})

# Establish the 4 major display areas a template usually has.
# In my quick sample, this code will make 68% of the Concerto 1 fields match
# up correct with the new Concerto 2 fields.  Magic will have to handle the other
# 42% of fields with stranger names like "Graphics (Full-Screen)"

# Note: This is replicated in config/initializers/17-required_data.rb because an instance must have fields.
Kind.all.each do |kind|
  field = Field.find_or_create_by_name({:name => kind.name, :kinds => Kind.where(:name => kind.name)})
end
# The time is just a special text field.
Field.find_or_create_by_name({:name => 'Time', :kinds => Kind.where(:name => 'Text')})

#Create an initial group
Group.find_or_create_by_name(:name => "Concerto Admins")

#Determine installed content types for enabling them in the inital feed
#This is not the ideal way but unfortunately they're not registered yet at this point
installed_content_types = { :Graphic=>"1", :Ticker=>"1" } # these are native
# enables the content types if the gems are found (even if they aren't going to be registered, unfortunately)
if Gem.loaded_specs.has_key? "concerto_simple_rss"
  installed_content_types.merge!({ :SimpleRss => "1" })
end
if Gem.loaded_specs.has_key? "concerto_remote_video"
  installed_content_types.merge!({ :RemoteVideo => "1" })
end
if Gem.loaded_specs.has_key? "concerto_weather"
  installed_content_types.merge!({ :Weather => "1" })
end

#Create an initial feed
Feed.find_or_create_by_name(:name => "Concerto", 
  :description => "Initial Concerto Feed", 
  :group_id => Group.first.id, 
  :is_viewable => 1, 
  :is_submittable => 1, 
  :content_types => installed_content_types)

#Create an initial template
@template = Template.find_or_create_by_name(:name => "Default Template", :author => "Concerto")

#Taking care to make this file upload idempotent
if Media.where(:file_name => "BlueSwooshNeo_16x9.jpg").empty?
  file = File.new("db/seed_assets/BlueSwooshNeo_16x9.jpg")
  @template.media.create(:file => file, :key => "original", :file_type => "image/jpg")
end

#Associate each field with a position in the template
concerto_template = Template.where(:name => "Default Template").first.id
Position.find_or_create_by_field_id_and_template_id(Field.where(:name => "Graphics").first.id,concerto_template, :top => ".026", :left => ".025", :bottom => ".796", :right => ".592", :style => "border:solid 2px #ccc;")
Position.find_or_create_by_field_id_and_template_id(Field.where(:name => "Ticker").first.id,concerto_template, :top => ".885", :left => ".221", :bottom => ".985", :right => ".975", :style => "color:#FFF; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important;")
Position.find_or_create_by_field_id_and_template_id(Field.where(:name => "Text").first.id,concerto_template, :top => ".015", :left => ".68", :bottom => ".811", :right => ".98", :style =>"color:#FFF; font-family:Frobisher, Arial, sans-serif;")
Position.find_or_create_by_field_id_and_template_id(Field.where(:name => "Time").first.id,concerto_template, :top => ".885", :left => ".024", :bottom => ".974", :right => ".18", :style => "color:#ccc; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important; letter-spacing:.12em !important;")

#Create a sample Full-Screen
Screen.find_or_create_by_name(:name => "Sample Screen", :location => "Cafe", :is_public => true, :owner_id => Group.first.id, :owner_type => "Group", :template_id => concerto_template, :width => 1024, :height => 768)

#Create initial subscriptions for the sample Screen
feed_id = Feed.first.id
screen_id= Screen.first.id
Field.where('name NOT IN (?)', ['Dynamic', 'Time']).each do |f|
  Subscription.where(:feed_id => feed_id, :field_id => f.id, :screen_id => screen_id, :weight => 1).first_or_create
end
