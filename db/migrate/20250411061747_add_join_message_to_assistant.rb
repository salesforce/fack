class AddJoinMessageToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :enable_channel_join_message, :boolean, default: false
  end
end
