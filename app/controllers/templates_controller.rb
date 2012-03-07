class TemplatesController < ApplicationController
  # GET /templates
  # GET /templates.xml
  def index
    @templates = Template.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @templates }
      format.js { }
    end
  end

  # GET /templates/1
  # GET /templates/1.xml
  def show
    @template = Template.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @template }
      format.js { }
    end
  end

  # GET /templates/new
  # GET /templates/new.xml
  def new
    @template = Template.new
    @template.media.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @template }
    end
  end

  # GET /templates/1/edit
  def edit
    @template = Template.find(params[:id])
    if(@template.media.empty?)
      @template.media.build
    end
  end

  # POST /templates
  # POST /templates.xml
  def create
    @template = Template.new(params[:template])
    @template.media.each do |media|
      media.key = "original"
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

  # PUT /templates/1
  # PUT /templates/1.xml
  def update
    @template = Template.find(params[:id])
    @template.media.each do |media|
      media.key = "original"
    end

    respond_to do |format|
      if @template.update_attributes(params[:template])
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
    @template.destroy

    respond_to do |format|
      format.html { redirect_to(templates_url) }
      format.xml  { head :ok }
    end
  end
  
  # GET /template/1/preview
  # Generate a preview of the template based on the request format.
  def preview
    @template = Template.find(params[:id])
    @media = @template.media.original.first
    @image = Magick::Image.from_blob(@media.file_contents).first
    @height = @image.rows
    @width = @image.columns
    
    jpg =  Mime::Type.lookup_by_extension(:jpg)  #JPG is getting defined elsewhere.
    if([jpg, Mime::PNG, Mime::HTML].include?(request.format))
      if !@template.positions.empty?
        dw = Magick::Draw.new
        @template.positions.each do |position|
          #Draw the rectangle
          dw.fill("grey")
          dw.stroke_opacity(0)
          dw.fill_opacity(0.6)
          dw.rectangle(@width*position.left, @height*position.top, @width*position.right, @height*position.bottom)
          
          #Layer the field name
          dw.stroke("black")
          dw.fill("black")
          dw.text_anchor(Magick::MiddleAnchor)
          dw.opacity(1)
          dw.pointsize = 100
          dw.text((@width*(position.left + position.right)/2),(@height*(position.top + position.bottom)/2+40),position.field.name)      
        end
        dw.draw(@image)
      end      

      case request.format
      when jpg
        @image.format = "JPG"
      when Mime::PNG
        @image.format = "PNG"
      end
    
      send_data @image.to_blob,
                :filename => "#{@template.name.underscore}.#{@image.format.downcase}_preview",
                :type => @image.mime_type, :disposition => 'inline'
    else
      respond_to do |format|
        format.svg
      end
    end
  end

  # PUT /templates/import
  # Import a template from an XML description and convert it to an actual
  # template model.
  #
  # TODO - This should be cleaned up, we should throw smarter errors too.
  def import
    xml_file = params[:xml]
    image_file = params[:image]
    @template = Template.new
    if xml_file.nil? || image_file.nil?
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @template.errors, :status => :unprocessable_entity }
      end
    else
      xml_data = xml_file.read
      if !xml_data.blank? && @template.import_xml(xml_data)
        @template.media.build({:key=>"original", :file => image_file})
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
end
