class AddDisableNonbotChatToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :disable_nonbot_chat, :boolean
  end
end
