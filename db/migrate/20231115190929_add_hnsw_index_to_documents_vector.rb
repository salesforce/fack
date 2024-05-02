# frozen_string_literal: true

class AddHnswIndexToDocumentsVector < ActiveRecord::Migration[7.0]
  def change
    remove_index :documents, name: 'index_documents_on_embedding'
  end
end
