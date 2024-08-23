class AddFieldsToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :input, :text
    add_column :assistants, :output, :text
    add_column :assistants, :instructions, :text
    add_column :assistants, :context, :text
  end
end
