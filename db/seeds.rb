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
Setting.ensure_defaults_exist

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

template_definitions = [
  {
    name: "BlueSwoosh", author: "Concerto Team", image: "db/seed_assets/BlueSwooshNeo_16x9.jpg",
    positions: [
      { field: main_field, top: ".026", left: ".025", bottom: ".796", right: ".592", style: "" },
      { field: ticker_field, top: ".885", left: ".221", bottom: ".985", right: ".975", style: "color:#FFF; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important;" },
      { field: sidebar_field, top: ".015", left: ".68", bottom: ".811", right: ".98", style: "color:#FFF; font-family:Frobisher, Arial, sans-serif;" },
      { field: time_field, top: ".885", left: ".024", bottom: ".974", right: ".18", style: "color:#ccc; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important; letter-spacing:.12em !important;" }
    ]
  },
  {
    name: "GraySwoosh", author: "Brian Zaik", image: "db/seed_assets/GraySwoosh_16x9.jpg",
    positions: [
      { field: time_field, top: ".01765", left: ".11", bottom: ".11765", right: ".335", style: "color:#333; font-family:Frobisher, sans-serif; font-size:1.05em; font-weight:bold; letter-spacing:0.07em;" },
      { field: ticker_field, top: ".023", left: ".45825", bottom: ".11", right: ".98845", style: "color:#000; font-family:Frobisher, sans-serif;" },
      { field: sidebar_field, top: ".2", left: ".04", bottom: ".95", right: ".38", style: "font-family:Frobisher, sans-serif; color:#FFF;" },
      { field: main_field, top: ".2", left: ".4125", bottom: ".95", right: ".975", style: "" }
    ]
  },
  {
    name: "Ribbon", author: "Brian Zaik", image: "db/seed_assets/Ribbon_16x9.jpg",
    positions: [
      { field: main_field, top: ".013", left: ".038", bottom: ".832", right: ".633", style: "border:solid 2px #999 !important;" },
      { field: sidebar_field, top: ".293", left: ".76", bottom: ".837", right: ".96", style: "color:#FFF !important; font-family:Arial, sans-serif !important;" },
      { field: ticker_field, top: ".867", left: ".012", bottom: ".986", right: ".572", style: "font-family:Arial, sans-serif !important;" },
      { field: time_field, top: ".033", left: ".84", bottom: ".233", right: ".972", style: "color:#ccc !important; font-family:Arial, sans-serif !important;" }
    ]
  },
  {
    name: "Ruby", author: "Brian Zaik", image: "db/seed_assets/Ruby_16x9.jpg",
    positions: [
      { field: time_field, top: ".0111111", left: ".689062", bottom: ".074074", right: ".990104", style: "font-family:Frobisher, Arial, sans-serif; color:#FFF;" },
      { field: main_field, top: ".196296", left: ".0421875", bottom: ".878703", right: ".605729", style: "font-family:Frobisher, Arial, sans-serif; color:#000; border:solid 1px #ccc;" },
      { field: ticker_field, top: ".0111111", left: ".078125", bottom: ".15", right: ".60625", style: "font-family:Frobisher, Arial, sans-serif; color:#FFF;" },
      { field: sidebar_field, top: ".116667", left: ".670833", bottom: ".819445", right: ".990625", style: "font-family:Frobisher, Arial, sans-serif; color:#FFF;" }
    ]
  },
  {
    name: "Simplicity", author: "Brian Michalski", image: "db/seed_assets/Simplicity.jpg",
    positions: [
      { field: main_field, top: "0", left: "0", bottom: "1", right: "1", style: "" }
    ]
  },
  {
    name: "Stoic", author: "Marc Ebuña", image: "db/seed_assets/Stoic_16x9.jpg",
    positions: [
      { field: time_field, top: ".90277", left: ".091146", bottom: ".99533", right: ".231146", style: "font-family:Frobisher, Arial, sans-serif; color:#FFF;" },
      { field: main_field, top: ".02315", left: ".016", bottom: ".83796", right: ".626", style: "font-family:Frobisher, Arial, sans-serif; color:#000;" },
      { field: ticker_field, top: ".90277", left: ".27", bottom: ".99533", right: ".97", style: "font-family:Frobisher, Arial, sans-serif; color:#FFF;" },
      { field: sidebar_field, top: ".01", left: ".652", bottom: ".81556", right: ".992", style: "font-family:Frobisher, Arial, sans-serif; color:#000;" }
    ]
  },
  {
    name: "Waves", author: "Marc Ebuña", image: "db/seed_assets/Waves_16x9.jpg",
    positions: [
      { field: time_field, top: ".858", left: ".691", bottom: ".975", right: ".938", style: "font-family:Frobisher, sans-serif; font-size:0.8em; font-weight:bold;" },
      { field: sidebar_field, top: ".009", left: ".712", bottom: ".809", right: ".967", style: "font-family:Frobisher, sans-serif;" },
      { field: main_field, top: ".009", left: ".046", bottom: ".816", right: ".641", style: "border:solid 2px #663333;" }
    ]
  }
]

template_definitions.each do |attrs|
  t = Template.find_or_initialize_by(name: attrs[:name], author: attrs[:author])
  next unless t.new_record?

  t.image = File.new(attrs[:image])
  attrs[:positions].each { |pos| t.positions.new(pos) }
  t.save!
end

template = Template.find_by!(name: "BlueSwoosh")

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

remote_feed = RemoteFeed.find_or_initialize_by(name: "Quote of the Day", group: demo_feed_group)
if remote_feed.new_record?
  remote_feed.description = "A sample service which returns a quote of the day. Feel free to suggest your own quotes @ https://github.com/bamnet/qod"
  remote_feed.url = "https://remotefeed-quotes-demo.concerto-signage.org/feed"
  remote_feed.save!

  suppress(Exception) do
    remote_feed.refresh
  end
end

puts "Seeding demo screen..."

demo_screen_group = Group.find_or_create_by!(name: "Demo Screen Owners", description: "Managers of the Demo Screen.")
screen = Screen.find_or_create_by!(name: "Demo Screen", template: template, group: demo_screen_group)
if screen.subscriptions.empty?
    screen.subscriptions.new(feed: general_feed, field: main_field)
    screen.subscriptions.new(feed: general_feed, field: ticker_field)
    screen.subscriptions.new(feed: landscape_feed, field: main_field)
    screen.subscriptions.new(feed: rss_feed, field: sidebar_field)
    screen.subscriptions.new(feed: remote_feed, field: ticker_field)
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

Graphic.all.each do |g|
  g.image.analyze if !g.image.analyzed?
end
