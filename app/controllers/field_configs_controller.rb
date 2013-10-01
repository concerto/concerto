class FieldConfigsController < ApplicationController
  before_filter :get_screen, :get_field
  
  def get_screen
    @screen = Screen.find(params[:screen_id])
  end

  def get_field
    @field = Field.find(params[:field_id])
  end

  # GET /screens/:screen_id/fields/:field_id/field_configs
  # GET /screens/:screen_id/fields/:field_id/field_configs.xml
  def index
    @field_configs = @screen.field_configs.where(:field_id => @field.id)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @field_configs }
    end
  end

  # PUT /screens/:screen_id/fields/:field_id/field_configs
  def update
    @field_configs = FieldConfig.update(params[:field_configs].keys, params[:field_configs].values)
    respond_to do |format|
      if @field_configs.all?{ |fc| fc.errors.empty? }
        format.html { redirect_to(screen_field_field_configs_path(@screen, @field), :notice => t(:parameters_updated)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @field_configs.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /screens/:screen_id/fields/:field_id/field_configs/1
  # DELETE /screens/:screen_id/fields/:field_id/field_configs/1.xml
  def destroy
    @field_config = FieldConfig.find(params[:id])
    auth!
    @field_config.destroy

    respond_to do |format|
      format.html { redirect_to(screen_field_field_configs_path(@screen, @field)) }
      format.xml  { head :ok }
    end
  end

end
