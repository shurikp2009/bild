class AddKeywordsToRemoteFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :remote_files, :keywords, :string
  end
end
