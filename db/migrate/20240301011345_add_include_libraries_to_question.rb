# frozen_string_literal: true

class AddIncludeLibrariesToQuestion < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :library_ids_included, :string, array: true, default: []
  end
end
