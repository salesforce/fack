class AddCreateDocOnApprovalToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :create_doc_on_approval, :boolean
  end
end
