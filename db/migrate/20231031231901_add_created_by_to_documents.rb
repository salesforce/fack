class AddCreatedByToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_reference :documents, :user, null: true, foreign_key: true
  end
end
