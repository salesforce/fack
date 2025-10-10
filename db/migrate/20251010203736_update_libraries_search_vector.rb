class UpdateLibrariesSearchVector < ActiveRecord::Migration[7.2]
  def up
    # Drop the existing search_vector column
    remove_column :libraries, :search_vector

    # Add the new search_vector column that includes both name and description
    add_column :libraries, :search_vector, :virtual, type: :tsvector,
                                                     as: "to_tsvector('english'::regconfig, COALESCE(name, '') || ' ' || COALESCE(description, ''))",
                                                     stored: true

    # Re-add the index
    add_index :libraries, :search_vector, using: :gin
  end

  def down
    # Drop the current search_vector column
    remove_column :libraries, :search_vector

    # Add back the original search_vector column (name only)
    add_column :libraries, :search_vector, :virtual, type: :tsvector,
                                                     as: "to_tsvector('english'::regconfig, (name)::text)",
                                                     stored: true

    # Re-add the index
    add_index :libraries, :search_vector, using: :gin
  end
end
