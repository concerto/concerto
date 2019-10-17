class TemplatesController < ApplicationController
  define_callbacks :show # controller callback for 'show' action
  ConcertoPlugin.install_callbacks(self) # Get the callbacks from plugins

  before_filter :get_type, only: [:new, :create, :import]
  respond_to :html, :json, :xml, :js
  responders :flash

  # GET /templates
  # GET /templates.xml
  # GET /templates.js
  def index
    @templates = Template.all
    auth!
    respond_with(@templates)
  end

  # GET /templates/1
  # GET /templates/1.xml
  # GET /templates/1.js
  def show
    @template = Template.find(params[:id])
    run_callbacks :show # Run plugin hooks
    auth!
    respond_with(@template) do |format|
      format.xml { render xml: @template.to_xml(include: [:positions])  }
    end
  end

  # GET /templates/new
  # GET /templates/new.xml
  def new
    @template = Template.new
    auth!
    # one for the graphic background and one for the css file
    @template.media.build()
    @template.media.build()
    respond_with(@template)
  end

  # GET /templates/1/edit
  def edit
    @template = Template.find(params[:id])
    auth!
    # the form contains two bogus fields used for file uploads -- :template_css, :template_image

    css_media = @template.media.where({key: 'css'})
    if !css_media.empty?
      @template_css = css_media.first.file_contents
    end
  end

  # POST /templates
  # POST /templates.xml
  def create
    @template = Template.new(template_params)
    auth!
    # set key based on file extension
    @template.media.each do |media|
      extension = (media.file_name.blank? ? nil : media.file_name.split('.')[-1].downcase)
      media.key = (extension == "css" ? "css" : "original") unless extension.nil?
    end

    # reject any empty media (key wont be set)
    @template.media.to_a.reject! {|i| i.key.blank?}

    respond_to do |format|
      if @template.save
        process_notification(@template, {}, process_notification_options({params: {template_name: @template.name}}))
        format.html { redirect_to(edit_template_path(@template), notice: t(:template_created)) }
        format.xml  { render xml: @template, status: :created, location: @template }
      else
        @type = "create"
        format.html { render :new }
        format.xml  { render xml: @template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /templates/1
  # PUT /templates/1.xml
  def update
    @template = Template.find(params[:id])
    auth!

    # get a copy of the params and remove the bogus file fields as we process them
    template_parameters = template_params
    # doens't matter which file is in which field because the file type is inspected for each
    [:template_css, :template_image].each do |file|
      if !template_parameters[file].nil?
        # for the files that were uploaded, determine their media key based on their extension
        new_media = @template.media.build({file: template_parameters[file]})
        extension = (new_media.file_name.blank? ? nil : new_media.file_name.split('.')[-1].downcase)
        new_media.key = (extension == "css" ? "css" : "original") unless extension.nil?

        # mark any existing @template.media with this same key as replaced (obsolete)
        @template.media.each do |m|
          m.key = 'replaced_' + m.key if m.key == new_media.key and m != new_media
        end
      end
      # remove the bogus file field from the collection so activemodel doesn't complain about it
      template_parameters.delete(file)
    end

    if @template.update_attributes(template_parameters)
      process_notification(@template, {}, process_notification_options({params: {template_name: @template.name}}))
      flash[:notice] = t(:template_updated)
    end

    respond_with(@template)
  end

  # DELETE /templates/1
  # DELETE /templates/1.xml
  def destroy
    @template = Template.find(params[:id])
    auth!

    unless @template.is_deletable?
      redirect_to(@template, notice: t(:cannot_delete_template, screens: @template.screens.collect { |s| s.name if can? :read, s}.join(", ")))
      return
    end

    process_notification(@template, {}, process_notification_options({params: {template_name: @template.name}}))
    @template.destroy
    respond_with(@template)
  end

  # GET /template/1/preview
  # Generate a preview of the template based on the request format.
  def preview
    @template = Template.find(params[:id])
    auth!(action: :preview)

    if stale?(last_modified: @template.last_modified.utc, etag: @template, public: true)
      # Hide the fields if the hide_fields param is set,
      # show them by default though.
      @hide_fields = false
      if !params[:hide_fields].nil?
        @hide_fields = [true, "true", 1, "1"].include?(params[:hide_fields])
      end

      # Hide the field names if the hide_text param is set,
      # show them by default though.
      @hide_text = false
      if !params[:hide_text].nil?
        @hide_text = [true, "true", 1, "1"].include?(params[:hide_text])
      end

      @only_fields = []
      if !params[:fields].nil?
        @only_fields = params[:fields].split(',').map{|i| i.to_i}
      end

      jpg =  Mime::Type.lookup_by_extension(:jpg)  #JPG is getting defined elsewhere.
      if([jpg, Mime::PNG, Mime::HTML].include?(request.format))
        @image = nil
        @image = @template.preview_image(@hide_fields, @hide_text, @only_fields)

        # Resize the image if needed.
        # We do this post-field drawing because RMagick seems to struggle with small font sizes.
        if  !params[:height].nil? || !params[:width].nil?
          require 'concerto_image_magick'
          @image = ConcertoImageMagick.resize(@image, params[:width].to_i, params[:height].to_i)
        end

        case request.format
          when jpg
            @image.format = "JPG"
          when Mime::PNG
            @image.format = "PNG"
        end

        data = nil
        data = @image.to_blob

        send_data data,
                  filename: "#{@template.name.underscore}.#{@image.format.downcase}_preview",
                  type: @image.mime_type, disposition: 'inline'
      else
        respond_to do |format|
          format.svg
        end
      end
    end
  end

  # PUT /templates/import
  # PUT /templates/import.xml
  # Import a template from an XML description and convert it to an actual
  # template model.
  def import
    @template = Template.new
    archive = params[:package]

    if @template.import_archive(archive)
      # is_hidden checkbox supercedes xml
      @template.is_hidden = template_params[:is_hidden]
      if @template.save
        process_notification(@template, {}, process_notification_options({params: {template_name: @template.name}}))
        flash[:notice] = t(:template_created)
      end
    end

    respond_with(@template)
  end

  def export
    @template = Template.find(params[:id])
    auth!
    send_file @template.export_archive, filename: sanitize_filename(@template.name + ".zip")
  end

private

  # Grab the method of template
  # creation we're working with.
  def get_type
    @type = params[:type] || 'import'
  end

  def template_params
    # :template_css and :template_file are two bogus fields used for file uploads when editing a template
    params.require(:template).permit(:name, :author, :descriptor, :image, :is_hidden, :template_css, :template_image, :owner_id, :owner_type, positions_attributes: [:field_id, :style, :top, :left, :bottom, :right, :id, :_destroy], media_attributes: [:file])
  end

  def sanitize_filename(filename)
    # Split the name when finding a period which is preceded by some
    # character, and is followed by some character other than a period,
    # if there is no following period that is followed by something
    # other than a period (yeah, confusing, I know)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    # We now have one or two parts (depending on whether we could find
    # a suitable period). For each of these parts, replace any unwanted
    # sequence of characters with an underscore
    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    # Finally, join the parts with a period and return the result
    return fn.join '.'
  end  
end
