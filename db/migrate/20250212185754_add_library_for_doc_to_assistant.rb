class AddLibraryForDocToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_reference :assistants, :library, null: true, foreign_key: true
  end
end
