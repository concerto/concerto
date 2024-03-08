# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Field.find_or_create_by!(name: "Main", alt_names: [ "Graphics" ])
Field.find_or_create_by!(name: "Sidebar", alt_names: [ "Text" ])
Field.find_or_create_by!(name: "Ticker")
Field.find_or_create_by!(name: "Time")

general_feed = Feed.find_or_create_by!(name: "General")

plain_ticker = RichText.find_or_initialize_by(name: "Welcome Ticker", text: "Welcome to Concerto!")
if plain_ticker.changed?
    plain_ticker.render_as = RichText.render_as[:plaintext]
    plain_ticker.save!
end

html_ticker = RichText.find_or_initialize_by(name: "HTML Ticker", text: "<b>Concerto</b> is digital signage for <i>everyone</i>.")
if html_ticker.changed?
    html_ticker.render_as = RichText.render_as[:html]
    html_ticker.save!
end

graphic1 = Graphic.find_or_initialize_by(name: "GenAI Poster", duration: 30)
if graphic1.changed?
    graphic1.image = File.new("db/seed_assets/genai_poster.png")
    graphic1.submissions.new(feed: general_feed)
    graphic1.save!
end

graphic2 = Graphic.find_or_initialize_by(name: "Welcome Robot", duration: 25)
if graphic2.changed?
    graphic2.image = File.new("db/seed_assets/welcome_robot.jpg")
    graphic2.submissions.new(feed: general_feed)
    graphic2.save!
end

rss_feed = RssFeed.find_or_initialize_by(name: "Yahoo News", description: "The latest news and headlines from Yahoo! News' RSS feed.")
if rss_feed.changed?
    rss_feed.url = "https://www.yahoo.com/news/rss"
    rss_feed.save!
end

landscape_feed = Feed.find_or_create_by!(name: "Landscapes")

(1..6).each do |i|
  landscape = Graphic.find_or_initialize_by(name: "Landscape #{i}", duration: 10 + 2*i)
  if landscape.changed?
    landscape.image = File.new("db/seed_assets/landscape_#{i}.jpg")
    landscape.submissions.new(feed: landscape_feed)
    landscape.save!
  end
end
