require 'zip'

class TemplatesController < ApplicationController
  before_filter :get_type, :only => [:new, :create, :import]
  respond_to :html, :json, :xml, :js

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
    auth!
    respond_with(@template) do |format|
      format.xml { render :xml => @template.to_xml(:include => [:positions])  }
    end
  end

  # GET /templates/new
  # GET /templates/new.xml
  def new
    @template = Template.new
    auth!
    @template.media.build
    respond_with(@template)
  end

  # GET /templates/1/edit
  def edit
    @template = Template.find(params[:id])
    auth!
    if(@template.media.empty?)
      @template.media.build
    end
  end

  # POST /templates
  # POST /templates.xml
  def create
    @template = Template.new(template_params)
    auth!
    @template.media.each do |media|
      media.key = "original"
    end

    respond_to do |format|
      if @template.save
        format.html { redirect_to(edit_template_path(@template), :notice => t(:template_created)) }
        format.xml  { render :xml => @template, :status => :created, :location => @template }
      else
        @type = "create"
        format.html { render :new }
        format.xml  { render :xml => @template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /templates/1
  # PUT /templates/1.xml
  def update
    @template = Template.find(params[:id])
    auth!
    @template.media.each do |media|
      media.key = "original"
    end

    if @template.update_attributes(template_params)
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
      redirect_to(@template, :notice => t(:cannot_delete_template, :screens => @template.screens.collect { |s| s.name if can? :read, s}.join(", ")))
      return
    end

    @template.destroy
    respond_with(@template)
  end

  # GET /template/1/preview
  # Generate a preview of the template based on the request format.
  def preview
    @template = Template.find(params[:id])
    auth!(:action => :read)

    if stale?(:last_modified => @template.last_modified.utc, :etag => @template, :public => true)
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
                  :filename => "#{@template.name.underscore}.#{@image.format.downcase}_preview",
                  :type => @image.mime_type, :disposition => 'inline'
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
    if archive.blank?
      @template.errors.add(:base, t(:template_import_requires_archive))
      respond_with(@template) do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @template.errors, :status => :unprocessable_entity }
      end
    else
      archive = archive.tempfile unless archive.is_a? Rack::Test::UploadedFile
      xml_file = image_file = nil
      zip_file = Zip::File.open(archive)
      zip_file.each do |entry|
        if entry.name.include? '.xml'
          xml_file = entry.get_input_stream
        else
          image_file = entry
        end
      end
      xml_data = xml_file.read
      if !xml_data.blank? && @template.import_xml(xml_data)
        @template.media.build({:key=>"original", :file_name => image_file.name,
                               :file_type => MIME::Types.type_for(image_file.name).first.content_type})
        @template.media.first.file_size = image_file.size
        @template.media.first.file_data = image_file.get_input_stream.read
      end

      if @template.save
        flash[:notice] = t(:template_created)
      end

      respond_with(@template)
    end
  end

private

  # Grab the method of template
  # creation we're working with.
  def get_type
    @type = params[:type] || 'import'
  end

  def template_params
    params.require(:template).permit(:name, :author, :descriptor, :image, :is_hidden, :positions_attributes => [:field_id, :style, :top, :left, :bottom, :right, :id, :_destroy], :media_attributes => [:file])
  end
end
