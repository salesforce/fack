# frozen_string_literal: true

class AddDocumentsCountToLibraries < ActiveRecord::Migration[6.0]
  def change
    add_column :libraries, :documents_count, :integer, default: 0, null: false

    # Initialize existing counts
    Library.find_each do |library|
      Library.reset_counters(library.id, :documents)
    end
  end
end
