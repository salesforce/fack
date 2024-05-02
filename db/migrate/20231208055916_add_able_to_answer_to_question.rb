# frozen_string_literal: true

class AddAbleToAnswerToQuestion < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :able_to_answer, :boolean, default: true
  end
end
