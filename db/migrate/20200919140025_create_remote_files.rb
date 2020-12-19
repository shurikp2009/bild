class CreateRemoteFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :remote_files do |t|
      t.string :name
      t.string :path
      t.integer :folder_id
      t.integer :server_id
      t.date :created_date
      t.string :headline
      t.text :caption
      t.string :byline
      t.string :credit
      t.integer :size

      t.date :modified_at

      t.string :type

      t.timestamps
    end
  end
end
