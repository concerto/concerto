class Frontend::FieldsController < ApplicationController
  layout false

  def content
    respond_to do |format|
      format.json { render :json => [] }
    end
  end
end
