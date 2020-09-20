require 'mini_magick'
require 'image_optim'

class RemoteFile < ApplicationRecord
  belongs_to :folder
  delegate :server, to: :folder

  scope :smallest_first, -> { order('size asc') }

  SIZES = {
    :small => "100"
  }

  def fetch_original
    unless File.exists?(local_path)
      server.ftp.getbinaryfile(path, local_path)
    end
  end

  def local_path(type = :original)
    File.join(folder.local_path(type), name)
  end

  def self.smallest
    smallest_first.first
  end

  def original
    MiniMagick::Image.open(local_path)
  end

  def create_all_types
    SIZES.keys.each { |type| create_type(type) }
  end

  def create_type(type)
    o = original
    size = SIZES[type]
    
    o.resize size 
    o.strip
    o.write local_path(type)

    ImageOptim.optimize_image!(local_path(type))
  end
end
