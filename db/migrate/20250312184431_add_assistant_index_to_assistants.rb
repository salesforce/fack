class AddAssistantIndexToAssistants < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE assistants
      ADD COLUMN search_vector tsvector
      GENERATED ALWAYS AS (to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, '') || ' ' || coalesce(instructions, ''))) STORED;
    SQL

    add_index :assistants, :search_vector, using: :gin
  end

  def down
    remove_index :assistants, :search_vector

    execute <<-SQL
      ALTER TABLE assistants
      DROP COLUMN search_vector;
    SQL
  end
end
