# frozen_string_literal: true

class AddShownOnceToApiToken < ActiveRecord::Migration[7.0]
  def change
    add_column :api_tokens, :shown_once, :boolean
  end
end
