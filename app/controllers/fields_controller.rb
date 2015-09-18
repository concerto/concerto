class FieldsController < ApplicationController
  before_action :set_field, only: [:edit, :update, :destroy]

  # GET /fields
  def index
    authorize! :read, Field
    @fields = Field.all
  end

  # GET /fields/new
  def new
    @field = Field.new
    auth!
  end

  # GET /fields/1/edit
  def edit
  end

  # POST /fields
  def create
    @field = Field.new(field_params)
    auth!
    if @field.save
      redirect_to fields_path, notice: t(:was_created, name: @field.name, theobj: t(:field))
    else
      render :new
    end
  end

  # PATCH/PUT /fields/1
  def update
    if @field.update(field_params)
      redirect_to fields_path, notice: t(:was_updated, name: @field.name, theobj: t(:field))
    else
      render :edit
    end
  end

  # DELETE /fields/1
  def destroy
    @field.destroy
    redirect_to fields_url, notice: t(:was_deleted, name: @field.name, theobj: t(:field))
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_field
      @field = Field.find(params[:id])
      auth!
    end

    # Only allow a trusted parameter "white list" through.
    def field_params
      params.require(:field).permit(:name, :kind_id)
    end
end
