Snippet.add :fetch_images do
  on

  def download_all
    RemoteFile.not_downloaded.find_each do |file|
      try_download(file)
    end
  end

  def try_download(file)
    ret = 0

    begin
      download_file(file)
    rescue MiniMagick::Invalid => invalid
      puts "Convertion fail, deleting file"
      `rm -rf "#{file.local_path}"`

      if ret < 1
        puts "  and retrying(#{ret}).."
        ret += 1
        retry
      else 
        puts "  and skipping"
        file.update(status: 'failed')
      end
    rescue => e
      puts "Exception[#{file.id}]: #{e} for file: #{file.path}"
      file.update(status: 'failed')
    end
  end

  def download_file(file)
    if file.size < 50_000
      file.fetch_original
      file.create_all_types
      
      `rm -rf "#{file.local_path}"`
      file.update(status: 'downloaded')
      file.symlink!
    else
      raise MiniMagick::Invalid
    end
  end

  def fc
    RemoteFile.failed.count
  end

  def dc
    RemoteFile.downloaded.count
  end
end