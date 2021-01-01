class AddDataToRemoteFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :remote_files, :title, :string
    add_column :remote_files, :author, :string
    add_column :remote_files, :caption, :string
    add_column :remote_files, :credit, :string
    add_column :remote_files, :data, :date
    add_column :remote_files, :src, :string
  end
end
