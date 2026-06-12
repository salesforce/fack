# frozen_string_literal: true

class AddDocLookbackDaysToQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :doc_lookback_days, :integer
  end
end
