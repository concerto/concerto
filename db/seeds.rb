# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seeding system groups and users..."

Group.find_or_create_by!(name: Group::REGISTERED_USERS_GROUP_NAME)
Group.find_or_create_by!(name: Group::SYSTEM_ADMIN_GROUP_NAME, description: "System administrators with full access to Concerto.")

system_user = User.find_or_create_by!(is_system_user: true, first_name: "Concerto", last_name: "System User")

puts "Seeding application settings..."

initial_settings = {
    oidc_issuer: "",
    oidc_client_id: "",
    oidc_client_secret: ""
}

initial_settings.each do |key, value|
  # Only create the setting if it doesn't already exist.
  # This prevents overwriting values if an admin has changed them.
  unless Setting.exists?(key: key)
    Setting[key] = value
    puts "  Created setting: #{key} = #{value}"
  else
    puts "  Setting already exists: #{key}"
    # If you *did* want to ensure the seed value is always the current value,
    # you would remove the 'unless' block:
    # Setting[key] = value
    # puts "  Updated setting: #{key} = #{value}"
  end
end

puts "Seeding clock..."

clock = Clock.find_or_initialize_by(name: "Clock", user: system_user)
if clock.new_record?
  clock.format = "M/d/yyyy{br}h:mm:ss a"
  clock.save!
end

puts "Seeding fields and initial template..."

main_field = Field.find_or_create_by!(name: "Main", alt_names: [ "Graphics" ])
sidebar_field = Field.find_or_create_by!(name: "Sidebar", alt_names: [ "Text" ])
ticker_field = Field.find_or_create_by!(name: "Ticker")
time_field = Field.find_or_create_by!(name: "Time")

template = Template.find_or_initialize_by(name: "BlueSwoosh", author: "Concerto Team")
if template.new_record?
    template.image = File.new("db/seed_assets/BlueSwooshNeo_16x9.jpg")
    template.positions.new(field: main_field, top: ".026", left: ".025", bottom: ".796", right: ".592", style: "")
    template.positions.new(field: ticker_field, top: ".885", left: ".221", bottom: ".985", right: ".975", style: "color:#FFF; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important;")
    template.positions.new(field: sidebar_field, top: ".015", left: ".68", bottom: ".811", right: ".98", style: "color:#FFF; font-family:Frobisher, Arial, sans-serif;")
    template.positions.new(field: time_field, top: ".885", left: ".024", bottom: ".974", right: ".18", style: "color:#ccc; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important; letter-spacing:.12em !important;")
    template.save!
end


puts "Seeding demo feeds..."

demo_feed_group = Group.find_or_create_by!(name: "Demo Feed Owners", description: "Managers of the Demo Feeds.")
general_feed = Feed.find_or_create_by!(name: "General", group: demo_feed_group)

rss_feed = RssFeed.find_or_initialize_by(name: "Yahoo News", description: "The latest news and headlines from Yahoo! News' RSS feed.", group: demo_feed_group)
if rss_feed.new_record?
    rss_feed.url = "http://news.yahoo.com/rss"
    rss_feed.save!

    suppress(Exception) do
      rss_feed.refresh
    end
end

landscape_feed = Feed.find_or_create_by!(name: "Landscapes", group: demo_feed_group)

puts "Seeding demo screen..."

demo_screen_group = Group.find_or_create_by!(name: "Demo Screen Owners", description: "Managers of the Demo Screen.")
screen = Screen.find_or_create_by!(name: "Demo Screen", template: template, group: demo_screen_group)
if screen.subscriptions.empty?
    screen.subscriptions.new(feed: general_feed, field: main_field)
    screen.subscriptions.new(feed: general_feed, field: ticker_field)
    screen.subscriptions.new(feed: landscape_feed, field: main_field)
    screen.subscriptions.new(feed: rss_feed, field: sidebar_field)
    screen.save!
end

FieldConfig.find_or_create_by!(screen: screen, field: time_field, pinned_content: clock)

puts "Seeding demo content..."

plain_ticker = RichText.find_or_initialize_by(name: "Welcome Ticker", text: "Welcome to Concerto!", user: system_user)
if plain_ticker.new_record?
    plain_ticker.render_as = RichText.render_as[:plaintext]
    plain_ticker.submissions.new(feed: general_feed)
    plain_ticker.save!
end

html_ticker = RichText.find_or_initialize_by(name: "HTML Ticker", text: "<b>Concerto</b> is digital signage for <i>everyone</i>.", user: system_user)
if html_ticker.new_record?
    html_ticker.render_as = RichText.render_as[:html]
    html_ticker.submissions.new(feed: general_feed)
    html_ticker.save!
end

graphic1 = Graphic.find_or_initialize_by(name: "GenAI Poster", duration: 30, user: system_user)
if graphic1.new_record?
    graphic1.image = File.new("db/seed_assets/genai_poster.png")
    graphic1.submissions.new(feed: general_feed)
    graphic1.save!
end

graphic2 = Graphic.find_or_initialize_by(name: "Welcome Robot", duration: 25, user: system_user)
if graphic2.new_record?
    graphic2.image = File.new("db/seed_assets/welcome_robot.jpg")
    graphic2.submissions.new(feed: general_feed)
    graphic2.save!
end

(1..6).each do |i|
  landscape = Graphic.find_or_initialize_by(name: "Landscape #{i}", duration: 10 + 2*i, user: system_user)
  if landscape.new_record?
    landscape.image = File.new("db/seed_assets/landscape_#{i}.jpg")
    landscape.submissions.new(feed: landscape_feed)
    landscape.save!
  end
end

Graphic.transaction do
  Graphic.all.each do |g|
    g.image.analyze if !g.image.analyzed?
  end
end
