class TypesController < ApplicationController
  # GET /types
  # GET /types.xml
  def index
    @types = Type.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @types }
    end
  end

  # GET /types/1
  # GET /types/1.xml
  def show
    @type = Type.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @type }
    end
  end

  # GET /types/new
  # GET /types/new.xml
  def new
    @type = Type.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @type }
    end
  end

  # GET /types/1/edit
  def edit
    @type = Type.find(params[:id])
  end

  # POST /types
  # POST /types.xml
  def create
    @type = Type.new(params[:type])

    respond_to do |format|
      if @type.save
        format.html { redirect_to(@type, :notice => 'Type was successfully created.') }
        format.xml  { render :xml => @type, :status => :created, :location => @type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /types/1
  # PUT /types/1.xml
  def update
    @type = Type.find(params[:id])

    respond_to do |format|
      if @type.update_attributes(params[:type])
        format.html { redirect_to(@type, :notice => 'Type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /types/1
  # DELETE /types/1.xml
  def destroy
    @type = Type.find(params[:id])
    @type.destroy

    respond_to do |format|
      format.html { redirect_to(types_url) }
      format.xml  { head :ok }
    end
  end
end
