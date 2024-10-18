class AddLastSyncResultToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :last_sync_result, :string
  end
end
