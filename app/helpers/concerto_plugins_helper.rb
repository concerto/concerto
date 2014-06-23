module ConcertoPluginsHelper
  def source_link
    if @concerto_plugin.source == 'rubygems'
      link_to(@concerto_plugin.source, "http://rubygems.org/gems/#{@concerto_plugin.gem_name}")
    else
      @concerto_plugin.source
    end
  end
  
  def plugin_sources
    t('concerto_plugins.sources').map { |key, value| [value, key] }
  end

  def plugin_source(source)
    t('concerto_plugins.sources')[source.to_sym]
  rescue
    # return raw value if someone messed up the localization entry
    source
  end

  def status_badge(enabled)
    puts enabled.inspect
    if enabled
      content_tag(:i, nil, :class => 'icon-check tooltip-basic', 'data-tooltip-text' => t('concerto_plugins.index.enabled_msg'))
    else
      content_tag(:i, nil, :class => 'icon-remove-sign tooltip-basic', 'data-tooltip-text' => t('concerto_plugins.index.disabled_msg'))
    end
  end
end
