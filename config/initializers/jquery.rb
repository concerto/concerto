# Switch the javascript_include_tag :defaults to use jquery instead of 
# the default prototype helpers.
ActionView::Helpers::AssetTagHelper::JAVASCRIPT_DEFAULT_SOURCES = ['jquery-1.4.2', 'jquery-ujs/src/rails']
ActionView::Helpers::AssetTagHelper::reset_javascript_include_default
