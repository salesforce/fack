class AddStatusToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :status, :integer, default: 0
  end
end
