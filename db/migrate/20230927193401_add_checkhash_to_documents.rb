# frozen_string_literal: true

class AddCheckhashToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :documents, :check_hash, :string
  end
end
