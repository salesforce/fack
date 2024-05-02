# frozen_string_literal: true

class AddLastLoginToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_login, :datetime
  end
end
