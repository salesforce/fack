class RemoveTokenTypeFromApiTokens < ActiveRecord::Migration[7.2]
  def change
    remove_column :api_tokens, :token_type, :integer
  end
end
