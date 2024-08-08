# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

general_feed = Feed.find_or_create_by!(name: "General")

plain_ticker = RichText.find_or_initialize_by(name: "Welcome Ticker", text: "Welcome to Concerto!")
if plain_ticker.new_record?
    plain_ticker.render_as = RichText.render_as[:plaintext]
    plain_ticker.save!
end

html_ticker = RichText.find_or_initialize_by(name: "HTML Ticker", text: "<b>Concerto</b> is digital signage for <i>everyone</i>.")
if html_ticker.new_record?
    html_ticker.render_as = RichText.render_as[:html]
    html_ticker.save!
end

graphic1 = Graphic.find_or_initialize_by(name: "GenAI Poster", duration: 30)
if graphic1.new_record?
    graphic1.image = File.new("db/seed_assets/genai_poster.png")
    graphic1.submissions.new(feed: general_feed)
    graphic1.save!
end

graphic2 = Graphic.find_or_initialize_by(name: "Welcome Robot", duration: 25)
if graphic2.new_record?
    graphic2.image = File.new("db/seed_assets/welcome_robot.jpg")
    graphic2.submissions.new(feed: general_feed)
    graphic2.save!
end

rss_feed = RssFeed.find_or_initialize_by(name: "Yahoo News", description: "The latest news and headlines from Yahoo! News' RSS feed.")
if rss_feed.new_record?
    rss_feed.url = "https://www.yahoo.com/news/rss"
    rss_feed.save!
end

landscape_feed = Feed.find_or_create_by!(name: "Landscapes")

(1..6).each do |i|
  landscape = Graphic.find_or_initialize_by(name: "Landscape #{i}", duration: 10 + 2*i)
  if landscape.new_record?
    landscape.image = File.new("db/seed_assets/landscape_#{i}.jpg")
    landscape.submissions.new(feed: landscape_feed)
    landscape.save!
  end
end

Field.transaction do
    main_field = Field.find_or_create_by!(name: "Main", alt_names: [ "Graphics" ])
    sidebar_field = Field.find_or_create_by!(name: "Sidebar", alt_names: [ "Text" ])
    ticker_field = Field.find_or_create_by!(name: "Ticker")
    time_field = Field.find_or_create_by!(name: "Time")

    Template.transaction do
        template = Template.find_or_initialize_by(name: "BlueSwoosh", author: "Concerto Team")
        if template.new_record?
            template.image = File.new("db/seed_assets/BlueSwooshNeo_16x9.jpg")
            template.positions.new(field: main_field, top: ".026", left: ".025", bottom: ".796", right: ".592", style: "border:solid 2px #ccc;")
            template.positions.new(field: ticker_field, top: ".885", left: ".221", bottom: ".985", right: ".975", style: "color:#FFF; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important;")
            template.positions.new(field: sidebar_field, top: ".015", left: ".68", bottom: ".811", right: ".98", style: "color:#FFF; font-family:Frobisher, Arial, sans-serif;")
            template.positions.new(field: time_field, top: ".885", left: ".024", bottom: ".974", right: ".18", style: "color:#ccc; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important; letter-spacing:.12em !important;""border:solid 2px #ccc;")
            template.save!
        end

        screen = Screen.find_or_create_by!(name: "Demo Screen", template: template)
        if screen.subscriptions.empty?
            screen.subscriptions.new(feed: general_feed, field: main_field)
            screen.subscriptions.new(feed: general_feed, field: ticker_field)
            screen.subscriptions.new(feed: landscape_feed, field: main_field)
            screen.subscriptions.new(feed: rss_feed, field: sidebar_field)
            screen.save!
        end
    end
end
