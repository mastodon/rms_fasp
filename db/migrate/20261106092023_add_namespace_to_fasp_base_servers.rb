class AddNamespaceToFaspBaseServers < ActiveRecord::Migration[8.1]
  def change
    add_column :fasp_base_servers, :namespace, :string, null: false
    add_index :fasp_base_servers, :namespace, unique: true
  end
end
