# frozen_string_literal: true

class AddEmbeddingToQuestion < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :embedding, :vector, limit: 1536
    add_index :questions, :embedding, using: :ivfflat, opclass: :vector_cosine_ops
  end
end
