class AddSyncedAtToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :synced_at, :datetime
  end
end
