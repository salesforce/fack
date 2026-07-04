class AddLibraryScopedActiveDocumentIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    add_index :documents,
              [:library_id, :created_at],
              where: "deleted_date IS NULL",
              name: "idx_documents_library_created_active",
              algorithm: :concurrently

    add_index :documents,
              [:library_id, :updated_at],
              order: { updated_at: :desc },
              where: "deleted_date IS NULL",
              name: "idx_documents_library_updated_active",
              algorithm: :concurrently
  end

  def down
    remove_index :documents,
                 name: "idx_documents_library_created_active",
                 algorithm: :concurrently

    remove_index :documents,
                 name: "idx_documents_library_updated_active",
                 algorithm: :concurrently
  end
end
