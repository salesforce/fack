class MakeWebhookOptionalInChats < ActiveRecord::Migration[6.0]
  def change
    change_column_null :chats, :webhook_id, true
    change_column_null :chats, :webhook_external_id, true
  end
end
