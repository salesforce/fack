class AddSearchVector < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :search_vector, :tsvector
    add_index :documents, :search_vector, using: :gin
  end
end
