class AddStatusToRemoteFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :remote_files, :status, :string
  end
end
