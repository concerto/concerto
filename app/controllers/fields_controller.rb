class FieldsController < ApplicationController
  before_filter :get_type
  
  def get_type
    @type = Type.find(params[:type_id])
  end

  # GET /type/:type_id/fields
  # GET /type/:type_id/fields.xml
  def index
    @fields = @type.fields

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields }
    end
  end

  # GET /type/:type_id/fields/1
  # GET /type/:type_id/fields/1.xml
  def show
    @field = Field.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /type/:type_id/fields/new
  # GET /type/:type_id/fields/new.xml
  def new
    @field = Field.new
    @field.type = @type

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /type/:type_id/fields/1/edit
  def edit
    @field = Field.find(params[:id])
  end

  # POST /type/:type_id/fields
  # POST /type/:type_id/fields.xml
  def create
    @field = Field.new(params[:field])
    @field.type = @type

    respond_to do |format|
      if @field.save
        format.html { redirect_to([@type, @field], :notice => 'Field was successfully created.') }
        format.xml  { render :xml => @field, :status => :created, :location => @field }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /type/:type_id/fields/1
  # PUT /type/:type_id/fields/1.xml
  def update
    @field = Field.find(params[:id])

    respond_to do |format|
      if @field.update_attributes(params[:field])
        format.html { redirect_to([@type, @field], :notice => 'Field was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /type/:type_id/fields/1
  # DELETE /type/:type_id/fields/1.xml
  def destroy
    @field = Field.find(params[:id])
    @field.destroy

    respond_to do |format|
      format.html { redirect_to(type_fields_url(@type)) }
      format.xml  { head :ok }
    end
  end
end
