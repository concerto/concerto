module ConcertoPluginsHelper
  def plugin_sources
    t('concerto_plugins.sources').map { |key, value| [value, key] }
  end

  def plugin_source(source)
    t('concerto_plugins.sources')[source.to_sym]
  rescue
    # return raw value if someone messed up the localization entry
    source
  end
end
