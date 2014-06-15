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

  def status_badge (enabled)
    content_tag :span, :class => "badge" + (!enabled ? " muted" : "") do 
      enabled ? t('.enabled') : t('.disabled')
    end
  end
end
