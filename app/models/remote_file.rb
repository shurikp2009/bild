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

  module Coder
    extend self

    def dump(object)
      YAML.dump(object)
    rescue => e
      if e.to_s.include?("invalid byte sequence")
        fixed = object.to_s.encode("UTF-8", invalid: :replace, undef: :replace)

        YAML.dump(eval(fixed)) # rescue binding.pry
      else
        raise
      end
    end

    def load(string)
      string.nil? ? {} : YAML.load(string)
    end
  end

  # serialize :image_metadata, Coder

  def fetch_original(force = false)
    already_exists = File.exists?(local_path)    
    rm if already_exists && force

    unless already_exists
      server.ftp.getbinaryfile(path, local_path)
    end

    save_metadata_and_keywords
  end

  def save_metadata_and_keywords
    update_attributes(:keywords => keywords_from_image) rescue nil
    File.write(local_path + '.md', original.data)
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

  def rm(type = :original)
    `rm -rf "#{local_path(type)}"`
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

  def keywords_from_image
    original.data["profiles"]["iptc"]["Keyword[2,25]"]
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
