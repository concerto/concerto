module Frontend::ScreensHelper

  def frontend_js_path(source)
    asset_paths.compute_public_path(source, 'frontend_js', :digest => false)
  end

end
