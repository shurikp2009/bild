class MainController < ApplicationController
  def index
    @folders = Folder.where(parent_id: nil).all
  end

  def find_folder
    @folder = Folder.find(params[:id])
  end

end
