# frozen_string_literal: true

class AddIndexToDocumentsExternalId < ActiveRecord::Migration[7.0]
  def change
    add_index :documents, :external_id, unique: true
  end
end
