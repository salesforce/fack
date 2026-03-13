# frozen_string_literal: true

class AddIndexToDocumentsSourceUrl < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :documents, :source_url, if_exists: true
    add_index :documents, :source_url, unique: true, where: "source_url IS NOT NULL AND source_url != ''", algorithm: :concurrently
  end
end
