class CreateServers < ActiveRecord::Migration[6.0]
  def change
    create_table :servers do |t|
      t.string :domain
      t.string :type

      t.timestamps
    end
  end
end
