# frozen_string_literal: true

class AddExternalIdToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :documents, :external_id, :string
  end
end
