class AddIndexToLibraryName < ActiveRecord::Migration[7.1]
  def change
    add_index :libraries, :name
  end
end
