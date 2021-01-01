class SharedController < ApplicationController
  include ActionController::Live

    def show
      send_file @file.local_path
    end
end