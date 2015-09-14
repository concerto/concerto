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
    @field_configs = @screen.field_configs.where(field_id: @field.id)
    auth!(object: @field_configs)
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @field_configs }
    end
  end

  # GET /screens/:screen_id/fields/:field_id/field_configs/new
  # GET /screens/:screen_id/fields/:field_id/field_configs/new.xml
  def new
    @field_config = FieldConfig.new(screen: @screen, field: @field)
    if params[:key]
      @field_config.key = params[:key]
    end
    auth!
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @field_config }
    end
  end

  # GET /screens/:screen_id/fields/:field_id/field_configs/1/edit
  def edit
    @field_config = FieldConfig.find(params[:id])
    auth!
  end

  # POST /screens/:screen_id/fields/:field_id/field_configs
  # POST /screens/:screen_id/fields/:field_id/field_configs.xml
  def create
    @field_config = FieldConfig.new(field_config_params)
    @field_config.screen = @screen
    @field_config.field = @field
    auth!
    respond_to do |format|
      if @field_config.save
        process_notification(@field_config, {}, process_notification_options({
          params: {
            field_config_name: @field_config.key,
            screen_name: @screen.name,
            field_name: @field.name
            }
          }))
        format.html { redirect_to screen_field_field_configs_path(@screen, @field), notice: t(:was_created, name: @field_config.key, theobj: t(:parameter)) }
        format.xml { head :ok }
      else
        format.html { render action: "new" }
        format.xml { render xml: @field_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /screens/:screen_id/fields/:field_id/field_configs/1
  # PATCH/PUT /screens/:screen_id/fields/:field_id/field_configs/1.xml
  def update
    @field_config = FieldConfig.find(params[:id])
    auth!

    respond_to do |format|
      if @field_config.update_attributes(field_config_params)
        process_notification(@field_config, {}, process_notification_options({
          params: {
            field_config_name: @field_config.key,
            screen_name: @screen.name,
            field_name: @field.name
            }
          }))
        format.html { redirect_to screen_field_field_configs_path(@screen, @field), notice: t(:was_updated, name: @field_config.key, theobj: t(:parameter)) }
        format.xml { head :ok }
      else
        format.html { render action: "edit" }
        format.xml { render xml: @field_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /screens/:screen_id/fields/:field_id/field_configs/1
  # DELETE /screens/:screen_id/fields/:field_id/field_configs/1.xml
  def destroy
    @field_config = FieldConfig.find(params[:id])
    auth!

    process_notification(@field_config, {}, process_notification_options({
      params: {
        field_config_name: @field_config.key,
        screen_name: @screen.name,
        field_name: @field.name
        }
      }))
    @field_config.destroy

    respond_to do |format|
      format.html { redirect_to screen_field_field_configs_url, notice: t(:was_deleted, name: @field_config.key, theobj: t(:parameter)) }
      format.xml { head :ok }
    end
  end

  private

    # Use this method to whitelist the permissible parameters. Example:
    # params.require(:person).permit(:name, :age)
    # Also, you can specialize this method with per-user checking of permissible attributes.
    def field_config_params
      params.require(:field_config).permit(:key, :value)
    end
end
