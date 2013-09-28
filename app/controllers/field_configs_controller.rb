class FieldConfigsController < ApplicationController
  before_filter :get_screen, :get_field
  
  def get_screen
    @screen = Screen.find(params[:screen_id])
  end

  def get_field
    @field = Field.find(params[:field_id])
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions
  # GET /screens/:screen_id/fields/:field_id/subscriptions.xml
  def index
    @field_configs = @screen.field_configs.where(:field_id => @field.id)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @field_configs }
    end
  end

end
