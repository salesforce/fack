class AddLastUsedToApiTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :api_tokens, :last_used, :datetime
  end
end
