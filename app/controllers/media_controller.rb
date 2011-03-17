class MediaController < ApplicationController
  def show
    @media = Media.find(params[:id])
    send_data @media.file_contents, :filename => @media.file_name, :type => @media.file_type, :disposition => 'inline'
  end
end
