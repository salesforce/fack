# frozen_string_literal: true

class AddStatusToQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :status, :integer, default: 2, null: false
  end
end
