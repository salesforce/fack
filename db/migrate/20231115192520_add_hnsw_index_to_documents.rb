class AddHnswIndexToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_index :documents, :embedding, using: :hnsw, opclass: :vector_l2_ops
  end
end
