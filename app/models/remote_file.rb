require 'mini_magick'
require 'image_optim'

class RemoteFile < ApplicationRecord
  belongs_to :folder
  delegate :server, to: :folder

  scope :smallest_first, -> { order('size asc') }
  scope :not_downloaded, -> { where("status <> ? or status is NULL", 'downloaded') }
  scope :failed, -> { where(status: 'failed') }
  scope :downloaded, -> { where(status: 'downloaded') }

  SIZES = {
    :small => "100"
  }

  def fetch_original
    unless File.exists?(local_path)
      server.ftp.getbinaryfile(path, local_path)
    end
  end

  def downloaded?
    File.exists?(local_path) && size == File.size(local_path)
  end

  def downloading?
    File.exists?(local_path) && File.size(local_path) < size
  end

  def download_progress
    File.size(local_path).to_f / size
  end

  def local_path(type = :original)
    File.join(folder.local_path(type), name)
  end

  def full_path(type = :original)
  end

  def type_exists?(type = :original)
    File.exists?(local_path(type))
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

  include Symlink
end
