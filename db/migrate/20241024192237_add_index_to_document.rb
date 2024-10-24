class AddIndexToDocument < ActiveRecord::Migration[7.1]
  def change
    add_index :documents, :check_hash
  end
end
