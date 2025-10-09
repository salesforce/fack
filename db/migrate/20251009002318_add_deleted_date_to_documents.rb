class AddDeletedDateToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :deleted_date, :datetime
  end
end
