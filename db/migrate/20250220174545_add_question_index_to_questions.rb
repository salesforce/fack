class AddQuestionIndexToQuestions < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE questions
      ADD COLUMN search_vector tsvector
      GENERATED ALWAYS AS (to_tsvector('english', question)) STORED;
    SQL

    add_index :questions, :search_vector, using: :gin
  end

  def down
    remove_index :questions, :search_vector

    execute <<-SQL
      ALTER TABLE questions
      DROP COLUMN search_vector;
    SQL
  end
end
