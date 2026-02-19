# frozen_string_literal: true

class AddIndexesToDocumentsForListPerformance < ActiveRecord::Migration[7.1]
  def change
    add_index :documents, :updated_at
    add_index :documents, :deleted_date
    add_index :documents, [:deleted_date, :updated_at]
  end
end
