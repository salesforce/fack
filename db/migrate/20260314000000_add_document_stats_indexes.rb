# frozen_string_literal: true

class AddDocumentStatsIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # Composite index for library show stats + index-only scan for enabled filter
    add_index :documents, %i[library_id deleted_date],
              name: 'index_documents_on_library_deleted_include_enabled',
              include: [:enabled],
              algorithm: :concurrently,
              if_not_exists: true

    # Partial index for docs without embedding (fast count)
    add_index :documents, %i[library_id deleted_date],
              name: 'index_documents_on_library_deleted_where_embedding_null',
              where: 'embedding IS NULL',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
