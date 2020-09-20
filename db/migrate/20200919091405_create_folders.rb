class CreateFolders < ActiveRecord::Migration[6.0]
  def change
    create_table :folders do |t|
      t.string :path
      t.string :name

      t.boolean :traversed
      
      t.integer :server_id
      t.integer :parent_id

      t.timestamps
    end
  end
end
