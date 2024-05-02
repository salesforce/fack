# frozen_string_literal: true

class AddTitleToDocument < ActiveRecord::Migration[7.0]
  def change
    add_column :documents, :title, :string
  end
end
