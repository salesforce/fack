# frozen_string_literal: true

class AddPromptToQuestion < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :prompt, :text
  end
end
