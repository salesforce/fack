class AddIndexToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_index :documents, :token_count
  end
end
