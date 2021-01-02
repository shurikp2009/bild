class FoldersController < ApplicationController
  before_action :find_folder, only: [:show]
  def index
    @folders = Folder.where(parent_id: nil).all
  end

  def show
    @folders 
  end

  def find_folder
    @folder = Folder.find(params[:id])
  end

  def cover
    cover = RemoteFile.first
  end
end
