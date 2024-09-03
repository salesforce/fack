class AddConfluenceSpacesToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :confluence_spaces, :string
  end
end
