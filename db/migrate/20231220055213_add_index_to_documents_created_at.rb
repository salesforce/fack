class AddIndexToDocumentsCreatedAt < ActiveRecord::Migration[7.0]
  def change
    add_index :documents, :created_at
  end
end
