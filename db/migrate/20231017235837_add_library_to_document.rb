class AddLibraryToDocument < ActiveRecord::Migration[7.0]
  def change
    add_reference :documents, :library, null: true, foreign_key: true
  end
end
