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
