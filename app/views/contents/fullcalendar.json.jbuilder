json.array! @content do |c|
    json.start c.start_time
    json.end c.end_time
    json.title c.name
    json.url c.id
end