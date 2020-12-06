class AddImageMetadataToRemoteFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :remote_files, :image_metadata, :text
  end
end
