class AddSourceUrlToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :source_url, :string
  end
end
