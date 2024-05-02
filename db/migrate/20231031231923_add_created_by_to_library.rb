# frozen_string_literal: true

class AddCreatedByToLibrary < ActiveRecord::Migration[7.0]
  def change
    add_reference :libraries, :user, null: true, foreign_key: true
  end
end
