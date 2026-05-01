# frozen_string_literal: true

module SearchHelper
  TYPE_BADGES = {
    "RichText"   => { icon: "document-text", label: "Text",        color: "bg-blue-100 text-blue-700" },
    "Graphic"    => { icon: "photo",         label: "Graphic",     color: "bg-blue-100 text-blue-700" },
    "Video"      => { icon: "film",          label: "Video",       color: "bg-blue-100 text-blue-700" },
    "Clock"      => { icon: "clock",         label: "Clock",       color: "bg-blue-100 text-blue-700" },
    "RssFeed"    => { icon: "rss",           label: "RSS Feed",    color: "bg-amber-100 text-amber-700" },
    "RemoteFeed" => { icon: "globe-alt",     label: "Remote Feed", color: "bg-amber-100 text-amber-700" },
    "Feed"       => { icon: "collection",    label: "Feed",        color: "bg-amber-100 text-amber-700" }
  }.freeze

  DEFAULT_TYPE_BADGE = { icon: "document-add", label: "Item", color: "bg-neutral-100 text-neutral-700" }.freeze

  def search_type_badge(record)
    badge = TYPE_BADGES.fetch(record.class.name, DEFAULT_TYPE_BADGE)
    content_tag(:span, class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{badge[:color]}") do
      heroicon(badge[:icon], class: "w-3 h-3 mr-1") + content_tag(:span, badge[:label])
    end
  end
end
