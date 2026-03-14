# frozen_string_literal: true

class AddIndexesToDocumentsQuestions < ActiveRecord::Migration[7.2]
  def change
    add_index :documents_questions, [:document_id, :question_id]
    add_index :documents_questions, [:question_id, :document_id]
  end
end
