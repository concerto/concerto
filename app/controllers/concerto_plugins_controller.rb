class ConcertoPluginsController < ApplicationController
  # GET /concerto_plugins
  # GET /concerto_plugins.json
  def index
    @concerto_plugins = ConcertoPlugin.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @concerto_plugins }
    end
  end

  # GET /concerto_plugins/1
  # GET /concerto_plugins/1.json
  def show
    @concerto_plugin = ConcertoPlugin.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @concerto_plugin }
    end
  end

  # GET /concerto_plugins/new
  # GET /concerto_plugins/new.json
  def new
    @concerto_plugin = ConcertoPlugin.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @concerto_plugin }
    end
  end

  # GET /concerto_plugins/1/edit
  def edit
    @concerto_plugin = ConcertoPlugin.find(params[:id])
  end

  # POST /concerto_plugins
  # POST /concerto_plugins.json
  def create
    @concerto_plugin = ConcertoPlugin.new(params[:concerto_plugin])

    respond_to do |format|
      if @concerto_plugin.save
        format.html { redirect_to @concerto_plugin, notice: 'Concerto plugin was successfully created.' }
        format.json { render json: @concerto_plugin, status: :created, location: @concerto_plugin }
      else
        format.html { render action: "new" }
        format.json { render json: @concerto_plugin.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /concerto_plugins/1
  # PUT /concerto_plugins/1.json
  def update
    @concerto_plugin = ConcertoPlugin.find(params[:id])

    respond_to do |format|
      if @concerto_plugin.update_attributes(params[:concerto_plugin])
        format.html { redirect_to @concerto_plugin, notice: 'Concerto plugin was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @concerto_plugin.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /concerto_plugins/1
  # DELETE /concerto_plugins/1.json
  def destroy
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    @concerto_plugin.destroy

    respond_to do |format|
      format.html { redirect_to concerto_plugins_url }
      format.json { head :no_content }
    end
  end
end
