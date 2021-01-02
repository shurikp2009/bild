class RemoteFilesController < ApplicationController
  before_action :find_file, only: [:download, :showf, :show]

  http_basic_authenticate_with name: "qwe", password: "123" 

    def download
      FetchFileJob.perform_later(params[:id])
      @file.update_attributes(status: 'downloading')
      redirect_back(fallback_location: @file.folder)
      send_file @file.local_path
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

    def showf
      @file.download_if_missing
      send_file @file.local_path
    end

    # def send
    #   begin
    #     send_file @file.file_path
    #   rescue
    #     flash[:error] = 'File not found.'
    #   end
    # end

    # def show
    #   @file = RemoteFile.find(params[:id])

    #   respond_to do |format|
    #   format.html
    #   format.jpg { render pdf: generate_pdf(@file) }
    # end




  def jpg
    file_name = params[:feed_image_path].split('/').last
    @filename ="#{Rails.root}/remote_files_path/#{file_name}"
    send_file(@filename ,
    :type => 'application/pdf/docx/html/htm/doc',
    :disposition => 'attachment')           
  end

end