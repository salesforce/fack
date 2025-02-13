class AddApprovalKeywordsToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :approval_keywords, :string
  end
end
