class FieldsController < ApplicationController
  before_filter :get_kind
  
  def get_kind
    @kind = Kind.find(params[:kind_id])
  end

  # GET /kind/:kind_id/fields
  # GET /kind/:kind_id/fields.xml
  def index
    @fields = @kind.fields

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields }
    end
  end

  # GET /kind/:kind_id/fields/1
  # GET /kind/:kind_id/fields/1.xml
  def show
    @field = Field.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /kind/:kind_id/fields/new
  # GET /kind/:kind_id/fields/new.xml
  def new
    @field = Field.new
    @field.kind = @kind

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /kind/:kind_id/fields/1/edit
  def edit
    @field = Field.find(params[:id])
  end

  # POST /kind/:kind_id/fields
  # POST /kind/:kind_id/fields.xml
  def create
    @field = Field.new(params[:field])
    @field.kind = @kind

    respond_to do |format|
      if @field.save
        format.html { redirect_to([@kind, @field], :notice => t(:field_created)) }
        format.xml  { render :xml => @field, :status => :created, :location => @field }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /kind/:kind_id/fields/1
  # PUT /kind/:kind_id/fields/1.xml
  def update
    @field = Field.find(params[:id])

    respond_to do |format|
      if @field.update_attributes(params[:field])
        format.html { redirect_to([@kind, @field], :notice => t(:field_updated)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /kind/:kind_id/fields/1
  # DELETE /kind/:kind_id/fields/1.xml
  def destroy
    @field = Field.find(params[:id])
    @field.destroy

    respond_to do |format|
      format.html { redirect_to(kind_fields_url(@kind)) }
      format.xml  { head :ok }
    end
  end
end
