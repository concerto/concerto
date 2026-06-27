class FieldsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_field, only: [ :edit, :update, :destroy ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @fields = policy_scope(Field).order(:name)
  end

  def new
    @field = Field.new
    authorize @field
  end

  def create
    @field = Field.new(field_params)
    authorize @field

    if @field.save
      redirect_to fields_path, notice: "Field was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @field
  end

  def update
    authorize @field
    if @field.update(field_params)
      redirect_to fields_path, notice: "Field was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @field
    if @field.destroy
      redirect_to fields_path, notice: "Field was successfully deleted."
    else
      redirect_to fields_path, alert: @field.errors.full_messages.join(", ")
    end
  end

  private

  def set_field
    @field = Field.find(params[:id])
  end

  def field_params
    permitted = params.require(:field).permit(:name, :alt_names)
    if permitted.key?(:alt_names)
      permitted[:alt_names] = permitted[:alt_names].to_s.split(",").map(&:strip).reject(&:blank?)
    end
    permitted
  end
end
