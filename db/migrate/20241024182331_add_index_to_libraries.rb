class AddIndexToLibraries < ActiveRecord::Migration[7.1]
  def change
    add_index :libraries, :documents_count
  end
end
