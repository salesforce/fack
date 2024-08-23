class AddDescriptionToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :description, :text
  end
end
