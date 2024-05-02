# frozen_string_literal: true

class AddIndexToQuestionsCreatedAt < ActiveRecord::Migration[7.0]
  def change
    add_index :questions, :created_at
  end
end
