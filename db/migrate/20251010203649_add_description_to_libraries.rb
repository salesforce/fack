class AddDescriptionToLibraries < ActiveRecord::Migration[7.2]
  def change
    add_column :libraries, :description, :text
  end
end
