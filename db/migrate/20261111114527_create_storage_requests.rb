class CreateStorageRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :storage_requests do |t|
      t.references :fasp_base_server, null: false, foreign_key: true
      t.references :ap_object, null: false, foreign_key: true
      t.references :media_file, null: true, foreign_key: true
      t.string :file_url, null: false, index: true
      t.integer :state, null: false, default: 0
      t.string :rejection_reason

      t.timestamps
    end
  end
end
