module ConcertoPluginsHelper
  def plugin_sources
    t('concerto_plugins.sources').map { |key, value| [value, key] }
  end
end
