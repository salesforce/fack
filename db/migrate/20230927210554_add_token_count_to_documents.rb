class AddTokenCountToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :documents, :token_count, :integer
  end
end
