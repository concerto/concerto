class KindsController < ApplicationController
  # GET /kinds
  # GET /kinds.xml
  def index
    @kinds = Kind.all
    auth!(:allow_empty => false)
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @kinds }
    end
  end

  # GET /kinds/1
  # GET /kinds/1.xml
  def show
    @kind = Kind.find(params[:id])
    auth!

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @kind.to_xml(:include => [:fields]) }
    end
  end

  # GET /kinds/new
  # GET /kinds/new.xml
  def new
    @kind = Kind.new
    auth!

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @kind }
    end
  end

  # GET /kinds/1/edit
  def edit
    @kind = Kind.find(params[:id])
    auth!
  end

  # POST /kinds
  # POST /kinds.xml
  def create
    @kind = Kind.new(kind_params)
    auth!

    respond_to do |format|
      if @kind.save
        format.html { redirect_to(@kind, :notice => 'Kind was successfully created.') }
        format.xml { render :xml => @kind, :status => :created, :location => @kind }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @kind.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /kinds/1
  # PUT /kinds/1.xml
  def update
    @kind = Kind.find(params[:id])
    auth!

    respond_to do |format|
      if @kind.update_attributes(kind_params)
        format.html { redirect_to(@kind, :notice => 'Kind was successfully updated.') }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @kind.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /kinds/1
  # DELETE /kinds/1.xml
  def destroy
    @kind = Kind.find(params[:id])
    auth!
    @kind.destroy

    respond_to do |format|
      format.html { redirect_to(kinds_url) }
      format.xml { head :ok }
    end
  end

  private

  # Restrict the allowed parameters to a select set defined in the model.
  def kind_params
    params.require(:kind).permit(:name)
  end

end
