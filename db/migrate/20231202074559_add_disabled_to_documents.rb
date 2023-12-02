class AddDisabledToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :documents, :disabled, :boolean
  end
end
