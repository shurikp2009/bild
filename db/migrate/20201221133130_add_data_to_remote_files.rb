class AddDataToRemoteFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :remote_files, :title, :string
    add_column :remote_files, :author, :string
    add_column :remote_files, :capt, :text
    add_column :remote_files, :credit, :string
  end
end
