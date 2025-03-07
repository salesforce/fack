class AddSlackReplyToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :slack_reply_only, :boolean
  end
end
