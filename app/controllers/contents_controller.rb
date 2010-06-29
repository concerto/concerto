class ContentsController < ApplicationController
  before_filter :get_content_const, :only => [:new, :create]
  
  # Grab the constent object for the type of
  # content we're working with.  Probably needs
  # additional error checking.
  def get_content_const
    begin
      @content_const = params[:type].camelize.constantize
    rescue
      @content_const = nil
    end
  end

  # GET /contents
  # GET /contents.xml
  def index
    @contents = Content.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @contents }
    end
  end

  # GET /contents/1
  # GET /contents/1.xml
  def show
    @content = Content.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @content }
    end
  end

  # GET /contents/new
  # GET /contents/new.xml
  def new
    if !content_types.map{|c| c.model_name.singular}.include?(params[:type])
      redirect_to new_content_path(:type=>'graphic')
    else
      type = params[:type].camelize
      
      @content = @content_const.new({:type => type})
      
      respond_to do |format|
        format.html { render :layout => 'splitview' } # new.html.erb
        format.xml  { render :xml => @content }
      end
    end
  end

  # GET /contents/1/edit
  def edit
    @content = Content.find(params[:id])
  end

  # POST /contents
  # POST /contents.xml
  def create
    @content =  @content_const.new(params[@content_const.model_name.singular])
    @feed_ids = []
    if params.has_key?("feed_id")
      @feed_ids = params[:feed_id].values
    end    

    respond_to do |format|
      if @content.save
        # Copy over the duration to each submission instance
        @feed_ids.each do |feed_id|
          @content.submissions << Submission.new({:feed_id => feed_id, :duration => @content.duration})
          #If you are the moderator,
          #then we might auto approve the submission here
        end
        @content.save #This second save adds the submissions
        format.html { redirect_to(@content, :notice => 'Content was successfully created.') }
        format.xml  { render :xml => @content, :status => :created, :location => @content }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contents/1
  # PUT /contents/1.xml
  def update
    @content = Content.find(params[:id])

    respond_to do |format|
      if @content.update_attributes(params[:content])
        format.html { redirect_to(@content, :notice => 'Content was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contents/1
  # DELETE /contents/1.xml
  def destroy
    @content = Content.find(params[:id])
    @content.destroy

    respond_to do |format|
      format.html { redirect_to(contents_url) }
      format.xml  { head :ok }
    end
  end
end
