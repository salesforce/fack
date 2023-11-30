class AddIndexToDocumentsVector < ActiveRecord::Migration[7.0]
  def change
    change_column :documents, :embedding, :vector, limit: 1536
    add_index :documents, :embedding, using: :ivfflat, opclass: :vector_cosine_ops
  end
end
