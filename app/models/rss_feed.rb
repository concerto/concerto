require "open-uri"

class RssFeed < Feed
    store_accessor :config, [ :url, :last_refreshed, :refresh_interval, :formatter ]

    # Destroy all associated content when an RSS feed is deleted
    before_destroy :destroy_associated_content, prepend: true

    def last_refreshed
      DateTime.parse(super) if super
    end

    def refresh_interval
      super.to_i if super
    end

    def headlines? = formatter == "headlines"
    def details? = formatter == "details"
    def ticker? = formatter == "ticker"
    def self.formatters
      { headlines: "headlines", details: "details", ticker: "ticker" }
    end

    def render_mode
      (ticker? ? RichText.render_as[:plaintext] : RichText.render_as[:html])
    end

    def refresh
      new_items = new_items()
      existing_content = content.all

      expired_time = Time.now

      existing_content.each.with_index do |content, index|
        # First, update all the existing content.
        if new_items.length > index
          content.render_as = render_mode,
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
            render_as: render_mode,
            name: "#{name} (#{index + 1})",
            text: item,
            user: User.find_by(is_system_user: true),
          )
        end
      end

      # Update the last refreshed time.
      self.last_refreshed = Time.now
      self.save
    end

    def new_items
        uri = URI.parse(url)
        doc = Nokogiri::XML(uri.open)

        title = doc.xpath("/rss/channel/title").text
        items = doc.xpath("//item").map do |item|
          { title: item.xpath("title").text,
            description: item.xpath("description").text }
        end

        contents = []

        if details?
          items.each do |item|
            description = ActionController::Base.helpers.sanitize(item[:description])
            contents << "<h1>#{CGI.escapeHTML(item[:title])}</h1><p>#{description}</p>"
          end
        elsif ticker?
          items.each do |item|
            contents << CGI.unescapeHTML(ActionController::Base.helpers.strip_tags(item[:title])).squish
          end
        else # headlines
          items.each_slice(5).with_index do |slice, index|
            item_titles = slice.map { |i| CGI.escapeHTML(i[:title]) }
            contents << "<h1>#{CGI.escapeHTML(title)}</h1><h2>#{item_titles.join("</h2><h2>")}</h2>"
          end
        end

        contents
    end

    # Deletes all unused content for this RSS feed
    def cleanup_unused_content
        content.unused.destroy_all
    end

    private

    def destroy_associated_content
        # Capture content IDs before Rails destroys the submission join.
        content_ids = content.pluck(:id)

        # Directly destroy the content records, not just the association.
        Content.where(id: content_ids).destroy_all
    end
end
