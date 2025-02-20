class AddLibraryIndexToLibraries < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
        ALTER TABLE libraries
        ADD COLUMN search_vector tsvector
        GENERATED ALWAYS AS (to_tsvector('english', name)) STORED;
    SQL

    add_index :libraries, :search_vector, using: :gin
  end

  def down
    remove_index :libraries, :search_vector

    execute <<-SQL
        ALTER TABLE libraries
        DROP COLUMN search_vector;
    SQL
  end
end
