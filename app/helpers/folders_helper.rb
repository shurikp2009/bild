module FoldersHelper
  def try_image_tag(file)
    if !file.symlink_exists?
      file.symlink!
    end

    image_tag file.symlink_name
  rescue
    ""
  end
end
