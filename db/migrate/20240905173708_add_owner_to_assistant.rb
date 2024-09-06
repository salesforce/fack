class AddOwnerToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_reference :assistants, :user, null: true, foreign_key: true
  end
end
