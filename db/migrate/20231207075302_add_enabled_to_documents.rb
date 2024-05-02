# frozen_string_literal: true

class AddEnabledToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :documents, :enabled, :boolean, default: true
  end
end
