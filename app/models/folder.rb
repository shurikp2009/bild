class Folder < ApplicationRecord
  belongs_to :parent, class_name: 'Folder', required: false
  has_many :files, class_name: 'RemoteFile'

  has_many :folders, foreign_key: 'parent_id'
  belongs_to :server
  
  DEFAULT = [
    '/NEW/SHATILO',
    '/NEW/LUBIMOV'
  ]

  TYPES = {
    :original => nil,
    :small    => 100 # width
  }

  LOCAL_ROOT = "#{Rails.root}/ftp"

  
  def self.for_path(path)
    name = path.split('/').last
    where(path: path, server: Server.default, name: name).first_or_create
  end

  def self.default
    for_path DEFAULT.first
  end

  def local_path(type = :original)
    full_path = File.join LOCAL_ROOT, server.domain, type.to_s, path
    `mkdir -p "#{full_path}"`
    full_path
  end

  def remote_list
    ftp = server.ftp
    ftp.chdir path
    ftp.list
  end

  def remote_entries
    remote_list.map { |string| FtpListEntry.new(string) }
  end

  def remote_folders
    remote_entries.select { |entry| entry.folder? }
  end

  def remote_files
    remote_entries.select {|entry| entry.file? }
  end

  def create_subfolders
    remote_folders.each { |entry| create_subfolder(entry) }
  end

  def create_subfolder(entry)
    self.class.where(server_id: server_id, parent_id: self.id, path: File.join(self.path, entry.name), name: entry.name).first_or_create
  end

  def create_file(entry)
    name = entry.name

    file = RemoteFile.where(folder_id: self.id, path: File.join(self.path, name), name: name).first_or_initialize

    file.attributes = { size: entry.size.try(:to_i), modified_at: entry.date }
    file.save!
  end

  def create_files
    remote_files.each { |entry| create_file entry }
  end

  def self_and_descendants_ids
    [ self.id, *folders.map(&:id) ]
  end

  def all_files
    RemoteFile.where(folder_id: self_and_descendants_ids)
  end

  def assign_name
    unless name.present?
      self.name = path.split('/').last
      self.save!
    end
  end

  def self.assign_names
    all.each do |folder|
      folder.assign_name
    end
  end

  def traverse(force = false)
    return if traversed
    
    create_files
    
    remote_folders.each do |name|
      subfolder = create_subfolder name
      subfolder.traverse
    end

    update_attribute(:traversed, true)
  rescue => e
    puts "Exception [#{path}]: #{e}"
  end
end
