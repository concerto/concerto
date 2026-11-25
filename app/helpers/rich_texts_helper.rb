module RichTextsHelper
  ACTIVE_HTML_TAGS = %w[
    script iframe frame frameset object embed applet svg math style link meta base template
  ].freeze

  EVENT_HANDLER_ATTR_PATTERN = /\Aon[a-z]/i
  DANGEROUS_URI_PATTERN = /\A(?:javascript|vbscript|data):/i
  DANGEROUS_STYLE_PATTERN = /expression\s*\(|javascript\s*:/i

  # Returns a list of human-readable descriptions of active/executable or
  # preview-stripped HTML constructs present in an HTML RichText. Returns an
  # empty array for plaintext content or HTML whose markup is preserved as-is
  # by the admin preview sanitizer.
  def rich_text_html_warnings(rich_text)
    return [] unless rich_text.is_a?(RichText) && rich_text.html? && rich_text.text.present?

    raw_html = rich_text.text.to_s
    raw_fragment = Nokogiri::HTML.fragment(raw_html)
    reasons = []

    found_active_tags = []
    found_event_handlers = []
    found_dangerous_uri = false
    found_srcdoc = false

    raw_fragment.traverse do |node|
      next unless node.element?

      tag = node.name.downcase
      found_active_tags << tag if ACTIVE_HTML_TAGS.include?(tag)

      node.attributes.each do |attr_name, attr_node|
        name = attr_name.downcase
        value = attr_node.value.to_s

        if name.match?(EVENT_HANDLER_ATTR_PATTERN)
          found_event_handlers << name
        elsif name == "srcdoc"
          found_srcdoc = true
        elsif value.gsub(/[\u0000-\u0020]+/, "").match?(DANGEROUS_URI_PATTERN)
          found_dangerous_uri = true
        elsif name == "style" && value.match?(DANGEROUS_STYLE_PATTERN)
          found_dangerous_uri = true
        end
      end
    end

    found_active_tags.uniq.each do |tag|
      reasons << "<#{tag}> element"
    end

    if found_event_handlers.any?
      handlers = found_event_handlers.uniq.first(3).join(", ")
      reasons << "inline event handler (#{handlers})"
    end

    reasons << "script/data URI" if found_dangerous_uri
    reasons << "srcdoc attribute" if found_srcdoc

    if reasons.empty?
      sanitized_fragment = Nokogiri::HTML.fragment(sanitize(raw_html).to_s)
      raw_tags, raw_attrs = extract_html_signature(raw_fragment)
      sanitized_tags, sanitized_attrs = extract_html_signature(sanitized_fragment)

      stripped_tags = raw_tags - sanitized_tags
      stripped_attrs = raw_attrs - sanitized_attrs

      if stripped_tags.any?
        reasons << "HTML stripped from preview (#{stripped_tags.first(3).map { |t| "<#{t}>" }.join(", ")})"
      elsif stripped_attrs.any?
        reasons << "attributes stripped from preview (#{stripped_attrs.first(3).join(", ")})"
      end
    end

    reasons
  end

  def rich_text_has_active_html?(rich_text)
    rich_text_html_warnings(rich_text).any?
  end

  private

  def extract_html_signature(fragment)
    tags = Set.new
    attrs = Set.new

    fragment.traverse do |node|
      next unless node.element?

      tags.add(node.name.downcase)
      node.attributes.each_key do |attr_name|
        attrs.add(attr_name.downcase)
      end
    end

    [ tags.to_a, attrs.to_a ]
  end
end
