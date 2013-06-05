class TemplatesController < ApplicationController
  before_filter :get_type, :only => [:new, :create, :import]

  # GET /templates
  # GET /templates.xml
  # GET /templates.js
  def index
    @templates = Template.all
    auth!

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @template }
      format.js { }
    end
  end

  # GET /templates/1
  # GET /templates/1.xml
  # GET /templates/1.js
  def show
    @template = Template.find(params[:id])
    auth!

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @template.to_xml(:include => [:positions]) }
      format.js { }
    end
  end

  # GET /templates/new
  # GET /templates/new.xml
  def new
    @template = Template.new
    auth!
    @template.media.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @template }
    end
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
        format.html { redirect_to(@template, :notice => t(:template_created)) }
        format.xml  { render :xml => @template, :status => :created, :location => @template }
      else
        format.html { redirect_to new_template_path(@template, :type => 'create'), :locals => {:template => @template} }
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

    respond_to do |format|
      if @template.update_attributes(template_params)
        format.html { redirect_to(@template, :notice => t(:template_updated)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /templates/1
  # DELETE /templates/1.xml
  def destroy
    @template = Template.find(params[:id])
    auth!
    if @template.destroy
      respond_to do |format|
        format.html { redirect_to(templates_url) }
        format.xml  { head :ok }
      end
    else
      redirect_to(@template, :notice => t(:cannot_delete_template))
      return 
    end
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
  #
  # TODO - This should be cleaned up, we should throw smarter errors too.
  def import
    xml_file = template_params[:descriptor]
    image_file = template_params[:image]
    @template = Template.new(template_params[:template])
    auth!
    
    if xml_file.nil? || image_file.nil?
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @template.errors, :status => :unprocessable_entity }
      end
    else
      begin
        xml_data = xml_file.read
        if !xml_data.blank? && @template.import_xml(xml_data)
          @template.media.build({:key=>"original", :file => image_file})
        end  
      rescue REXML::ParseException
        raise t(:template_import_error)
      end

      respond_to do |format|
        if @template.save
          format.html { redirect_to(@template, :notice => t(:template_created)) }
          format.xml  { render :xml => @template, :status => :created, :location => @template }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @template.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

private

  # Grab the method of template
  # creation we're working with.
  def get_type
    @type = params[:type] || 'import'
  end

  def template_params
    params.require(:template).permit(:name, :author, :descriptor, :image, :is_hidden, :original_width, :original_height)
  end
end
