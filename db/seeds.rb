# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

#It's important to use find_or_create_by_{attribute} so as to prevent duplicate creation of records

# Populate the 3 major 'kinds' of content we know as of now.
# There is discussion to move this to a static array / config elsewhere,
# but I don't have a solid grasp on the system-wide reprecussions of that
# change at the moment.

["Graphics", "Ticker", "Text", "Dynamic"].each do |kind|
  Kind.find_or_create_by_name kind
end

# Establish the 4 major display areas a template usually has.
# In my quick sample, this code will make 68% of the Concerto 1 fields match
# up correct with the new Concerto 2 fields.  Magic will have to handle the other
# 42% of fields with stranger names like "Graphics (Full-Screen)"

Kind.all.each do |kind|
  field = Field.find_or_create_by_name({name: kind.name, kind: Kind.where(name: kind.name).first})
end
# The time is just a special text field.
Field.find_or_create_by_name({name: 'Time', kind: Kind.where(name: 'Text').first})

#Create an initial group
Group.find_or_create_by_name(name: "Concerto Admins")

#Create an initial feed
Feed.find_or_create_by_name(name: "Concerto", description: "Initial Concerto Feed", group_id: 1, is_viewable: 1, is_submittable: 1, content_types: { Graphics: 1, Ticker: 1})

#Create an initial template
@template = Template.find_or_create_by_name(name: "Default Template", author: "Concerto")

#Taking care to make this file upload idempotent
if Media.where(file_name: "BlueSwooshNeo_16x9.jpg").empty?
  file = File.new("db/seed_assets/BlueSwooshNeo_16x9.jpg")
  @template.media.create(file: file, key: "original", file_type: "image/jpg")
end

#Associate each field with a position in the template
concerto_template = Template.where(name: "Default Template").first.id
Position.find_or_create_by_field_id_and_template_id(Field.where(name: "Graphics").first.id,concerto_template, top: ".026", left: ".025", bottom: ".796", right: ".592", style: "border:solid 2px #ccc;")
Position.find_or_create_by_field_id_and_template_id(Field.where(name: "Ticker").first.id,concerto_template, top: ".885", left: ".221", bottom: ".985", right: ".975", style: "color:#FFF; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important;")
Position.find_or_create_by_field_id_and_template_id(Field.where(name: "Text").first.id,concerto_template, top: ".015", left: ".68", bottom: ".811", right: ".98", style:"color:#FFF; font-family:Frobisher, Arial, sans-serif;")
Position.find_or_create_by_field_id_and_template_id(Field.where(name: "Time").first.id,concerto_template, top: ".885", left: ".024", bottom: ".974", right: ".18", style: "color:#ccc; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important; letter-spacing:.12em !important;")
