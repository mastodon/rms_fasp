class CreateApObjects < ActiveRecord::Migration[8.1]
  def change
    create_table :ap_objects do |t|
      t.string :uri, null: false, index: { unique: true }
      t.boolean :public
      t.string :media_urls, array: true

      t.timestamps
    end
  end
end
