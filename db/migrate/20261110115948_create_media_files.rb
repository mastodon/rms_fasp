class CreateMediaFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :media_files do |t|
      t.integer :file_size, null: false
      t.string :sha512, null: false, index: { unique: true }
      t.string :content_type, null: false
      t.integer :width
      t.integer :height

      t.timestamps
    end
  end
end
