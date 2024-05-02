# frozen_string_literal: true

class AddUserToApiToken < ActiveRecord::Migration[7.0]
  def change
    add_reference :api_tokens, :user, null: false, foreign_key: true
  end
end
