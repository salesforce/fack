class AddNameToApiToken < ActiveRecord::Migration[7.0]
  def change
    add_column :api_tokens, :name, :string
  end
end
