class AddNameToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :name, :string
  end
end
