# frozen_string_literal: true

class AddIndexToDocumentsOnQuestionsCount < ActiveRecord::Migration[6.0]
  def change
    add_index :documents, :questions_count
  end
end
