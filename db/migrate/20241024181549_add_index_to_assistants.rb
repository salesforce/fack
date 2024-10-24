class AddIndexToAssistants < ActiveRecord::Migration[7.1]
  def change
    add_index :assistants, :status
  end
end
