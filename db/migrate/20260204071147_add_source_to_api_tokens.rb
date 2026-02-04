class AddSourceToApiTokens < ActiveRecord::Migration[7.2]
  def change
    add_column :api_tokens, :source, :string, default: 'web', null: false
    add_index :api_tokens, :source
  end
end
