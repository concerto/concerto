require "open-uri"

class RssFeed < Feed
    store_accessor :config, :url

    def refresh
      new_items = new_items()
      existing_content = content.all

      expired_time = Time.now

      existing_content.each.with_index do |content, index|
        # First, update all the existing content.
        if new_items.length > index
          content.text = new_items[index]
          content.name = "#{name} (#{index + 1})"
          content.start_time = nil
          content.end_time = nil
        else
          # Then, expire any un-unpdated content.
          content.text = ""
          content.name = "#{name} (unused)"
          content.end_time = expired_time
        end
        content.save
      end

      # If there is any new items left, create new RichText content.
      offset = (new_items.length - existing_content.length)
      if offset > 0
        new_items[existing_content.length..].each.with_index do |item, index|
          content << RichText.new(
            render_as: "html",
            name: "#{name} (#{index + 1})",
            text: item
          )
        end
      end
      ""
    end

    def new_items
        doc = Nokogiri::XML(URI.open(url))

        title = doc.xpath("/rss/channel/title").text
        items = doc.xpath("//item").map do |item|
          item.xpath("title").text
        end

        contents = []

        items.each_slice(5).with_index do |slice, index|
          text = "<h1>#{title}</h1><h2>#{slice.join("</h2><h2>")}</h2>"
          contents.push(text)
        end

        contents
    end
end
