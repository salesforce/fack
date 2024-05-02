# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents do |t|
      t.text :document
      t.string :url
      t.integer :length

      t.timestamps
    end
  end
end
