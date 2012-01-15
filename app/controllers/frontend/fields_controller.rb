class Frontend::FieldsController < ApplicationController
  layout false

  def contents
    respond_to do |format|
      format.json { render :json => [] }
    end
  end
end
