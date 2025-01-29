class AddLibrarySearchTextToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :library_search_text, :string
  end
end
