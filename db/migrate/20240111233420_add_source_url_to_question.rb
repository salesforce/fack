# frozen_string_literal: true

class AddSourceUrlToQuestion < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :source_url, :string
  end
end
