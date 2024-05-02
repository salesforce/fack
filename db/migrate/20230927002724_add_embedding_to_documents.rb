# frozen_string_literal: true

class AddEmbeddingToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :documents, :embedding, :vector
  end
end
