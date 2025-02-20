class AddSoqlToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :soql, :text
  end
end
