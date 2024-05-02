# frozen_string_literal: true

class AddSourceUrlToLibrary < ActiveRecord::Migration[7.0]
  def change
    add_column :libraries, :source_url, :string
  end
end
