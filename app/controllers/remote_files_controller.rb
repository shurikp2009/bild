class RemoteFilesController < ApplicationController
  before_action :find_file

  def download
    FetchFileJob.perform_later(params[:id])
    @file.update_attributes(status: 'downloading')
    redirect_back(fallback_location: @file.folder)
  end

  def find_file
    @file = RemoteFile.find(params[:id])
  end
end
