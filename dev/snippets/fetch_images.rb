Snippet.add :fetch_images do
  on

  def download_all
    RemoteFile.not_downloaded.smallest_first.find_each do |file|
      try_download(file)
    end
  end

  def try_download(file)
    ret = 0

    begin
      download_file(file)
    rescue MiniMagick::Invalid => invalid
      raise if @raise_all
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
      raise if @raise_all
      puts "Exception[#{file.id}]: #{e} for file: #{file.path}"
      file.update(status: 'failed')
    end
  end

  def shurik?
    @_shurik = @_shurik.nil? ? `hostname`.include?('Alexanders-MBP') : @_shurik
  end

  def raise_all!
    @raise_all = true
  end

  def no_raise
    @raise_all = false
  end

  def download_file(file)
    raise MiniMagick::Invalid if shurik? && file.size > 50_000
    
    puts "Downloading(#{file.id})..."
    file.fetch_original
    puts "Converting..."
    file.create_all_types
    
    `rm -rf "#{file.local_path}"`
    file.update(status: 'downloaded')
    puts "Success: #{file.local_path}"
    file.symlink!
  end

  def fc
    RemoteFile.failed.count
  end

  def dc
    RemoteFile.downloaded.count
  end
end