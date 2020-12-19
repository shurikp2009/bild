class RemoteFilesController < ApplicationController
  before_action :find_file, only: [:download]

  def download
    FetchFileJob.perform_later(params[:id])
    @file.update_attributes(status: 'downloading')
    redirect_back(fallback_location: @file.folder)
  end

  def index
    scope = RemoteFile.all
    
    if params[:q]
      scope = scope.where("LOWER(keywords) like '%#{params[:q].downcase}%'")
    end

    @files = scope
  end

  def find_file
    @file = RemoteFile.find(params[:id])
  end

  def show
    begin
      send_file @file.file_path
    rescue
      flash[:error] = 'File not found.'
    end
  end


end
