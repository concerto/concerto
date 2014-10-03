module Frontend::ScreensHelper

  def frontend_js_path(source)
    asset_path('frontend_js/' + source, :digest => false)
  end

end
