module RemoteFile::Symlink
  def symlink_name(type = :small)
    ext = name.split('.').last
    symlink_name = "#{id}_#{type}.#{ext}"
  end
  
  def symlink_dir
    "#{Rails.root}/app/assets/images"
  end

  def symlink_path(type = :small)
    File.join symlink_dir, symlink_name(type)
  end

  def symlink!(type = :small)
    sl_name = symlink_name(type)
    `cd #{symlink_dir} && rm -rf #{sl_name} && ln -s "#{local_path(type)}" #{sl_name}`
  end

  def symlink_exists?(type = :small)
    File.exists? symlink_path(type)
  end
end