namespace :frontendjs do

  DEBUG_NONE = 0
  DEBUG_NORMAL = 1
  DEBUG_SUPER = 2

  @frontend_js_path = Pathname("public/frontend_js")
  @closure_library_path = Pathname("vendor/tools/closure")
  @closure_builder_path = Pathname("closure/bin/build/closurebuilder.py")
  @closure_compiler_path = Pathname("vendor/tools")
  @closure_compiler_name = Pathname("compiler.jar")

  @base_path = Rails.root
  @closure_library = @base_path + @closure_library_path
  @compiler_jar = @base_path + @closure_compiler_path + Pathname("compiler.jar")
  @closure_builder = @closure_library + @closure_builder_path


  desc "compiles frontend.js"
  task :compile, [:debug] => [:setup, :environment] do |_, args|

    args.with_defaults(:debug => DEBUG_NONE)
    debug_mode = args[:debug].to_i

    options = {
        namespace: "concerto.frontend.Screen",
        compiler_jar: @compiler_jar,
    }
    compiler_flags = {}

    options[:root] = [@closure_library, @base_path + @frontend_js_path]

    plugins = find_plugins
    options[:root] += plugins.map{|plugin| plugin.engine.root + @frontend_js_path}

    options[:output_mode] = case debug_mode
                             when DEBUG_NONE, DEBUG_NORMAL then "compiled"
                             when DEBUG_SUPER then "script"
                           end


    if debug_mode == DEBUG_NONE
      compiler_flags.merge!({
          externs:  @base_path + @frontend_js_path + Pathname("screen_options.js"),
          compilation_level: "ADVANCED_OPTIMIZATIONS",
      })
    end

    debug_suffix = case debug_mode
               when DEBUG_NONE then ""
               when DEBUG_NORMAL then "_debug"
               when DEBUG_SUPER then "_superdebug"
             end

    frontend_file_name = Pathname("frontend#{ debug_suffix }.js")
    frontend_file = @base_path + @frontend_js_path + frontend_file_name
    frontend_file.delete if frontend_file.exist?

    # Add source map
    compiler_flags.merge!({
      source_map_format: "V3",
      create_source_map: frontend_file.to_s + ".map",
    })

    options[:compiler_flags] = compiler_flags if !compiler_flags.empty?

    find_and_require_content_types(plugins)

    puts "WARNING: Remove frontend_superdebug.js and try again " if (@base_path + @frontend_js_path + Pathname("frontend_superdebug.js")).exist?

    `#{@closure_builder} #{serialize_options(options).join(' ')} > #{frontend_file}`
    raise "Could not build #{frontend_file_name}" unless frontend_file.exist?

    correct_source_map_paths compiler_flags[:create_source_map]
    # Append source map annotation to generated js file
    File.open(frontend_file, "a") do |f|
      f.write("//# sourceMappingURL=#{frontend_file_name}.map")
    end

  end

  task :setup do
    if !@closure_builder.exist?
      puts "Setting up closure library"
      `git submodule init`
      `git submodule update`

      if !@closure_builder.exist?
        raise "Could not setup closure library"
      end
    end

    if !@closure_builder.executable?
      `chmod +x #{@closure_builder}`
    end

    if !@compiler_jar.exist?
      puts "Downloading latest closure compiler"
      `cd #{@closure_compiler_path}; curl -O http://dl.google.com/closure-compiler/compiler-latest.zip && unzip -qq compiler-latest.zip #{@closure_compiler_name} && rm compiler-latest.zip`

      if !@compiler_jar.exist?
        raise "compiler.jar not found.\nDownload it from http://dl.google.com/closure-compiler/compiler-latest.zip and drop it into #{@closure_compiler_path}."
      end
    end
  end

  def find_plugins
    ConcertoPlugin.all.select{|plugin| plugin.engine && (plugin.engine.root + @frontend_js_path).directory?}
  end

  def serialize_options(options)
    options.map do |k, v|
      if v.is_a? Array
        v.map {|v2| ["--#{k}='#{v2}'"]}
      elsif v.is_a? Hash
        serialize_options(v).map{|c| ["--#{k}='#{c}'"]}
      else
        ["--#{k}='#{v}'"]
      end
    end.flatten
  end

  def find_and_require_content_types(plugins)
    requires = []
    plugins.each do |plugin|
      contents = plugin.engine.root + @frontend_js_path + Pathname("contents")
      next if !contents.directory?

      Dir.glob(contents + Pathname("*.js")) do |js_file|
        File.open(js_file) do |file|
          file.each_line do |line|
            match = /goog\.provide\(['"]([^'"]+)['"]\)\;/.match(line)
            if match
              requires << match.captures.first
              break
            end
          end
        end
      end
    end

    return if requires.empty?

    content_types_file = @frontend_js_path + Pathname("content_types.js")
    content = ""
    File.open(content_types_file, "r") do |file|
      file.each_line do |line|
        content += line
        break if line.start_with? "//= plugins"
      end
    end

    requires.sort.each do |r|
      content += "\ngoog.require('#{r}');"
    end

    File.open(content_types_file, 'w') do |file|
      file.write(content)
    end
  end

  def correct_source_map_paths(file)
    source_map = JSON.parse(File.read(file))
    relative_frontend_js_path = Pathname("frontend_js")

    source_map["sources"].map!{|p| p.sub(@closure_library.to_s, "closure-library")}
    source_map["sources"].map!{|p| p.sub("#{@base_path + @frontend_js_path}/", "") }
    
    # Correct paths proforma for other sources outside of the public directory (e.g. plugin js files)
    # You need to copy/link those files to the main public folder for debugging
    source_map["sources"].map!{|p| p.sub(/.*\/#{relative_frontend_js_path}\//, "") }

    File.open(file, "w") do |f|
      f.write(JSON.generate(source_map))
    end
  end
end