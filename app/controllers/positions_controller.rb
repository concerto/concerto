class PositionsController < ApplicationController
  before_filter :get_template
  
  def get_template
    @template = Template.find(params[:template_id])
  end
  
  # GET /templates/:template_id/positions
  # GET /templates/:template_id/positions.xml
  def index
    @positions = @template.positions

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @positions }
    end
  end

  # GET /templates/:template_id/positions/1
  # GET /templates/:template_id/positions/1.xml
  def show
    @position = Position.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @position }
    end
  end

  # GET /templates/:template_id/positions/new
  # GET /templates/:template_id/positions/new.xml
  def new
    @position = Position.new
    @position.template = @template

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @position }
    end
  end

  # GET /templates/:template_id/positions/1/edit
  def edit
    @position = Position.find(params[:id])
  end

  # POST /templates/:template_id/positions
  # POST /templates/:template_id/positions.xml
  def create
    @position = Position.new(params[:position])
    @position.template = @template

    respond_to do |format|
      if @position.save
        format.html { redirect_to([@template, @position], :notice => 'Position was successfully created.') }
        format.xml  { render :xml => @position, :status => :created, :location => @position }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @position.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /templates/:template_id/positions/1
  # PUT /templates/:template_id/positions/1.xml
  def update
    @position = Position.find(params[:id])

    respond_to do |format|
      if @position.update_attributes(params[:position])
        format.html { redirect_to([@template, @position], :notice => 'Position was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @position.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /templates/:template_id/positions/1
  # DELETE /templates/:template_id/positions/1.xml
  def destroy
    @position = Position.find(params[:id])
    @position.destroy

    respond_to do |format|
      format.html { redirect_to(template_positions_url(@template)) }
      format.xml  { head :ok }
    end
  end
end
