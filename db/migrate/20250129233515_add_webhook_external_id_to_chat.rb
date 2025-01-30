class AddWebhookExternalIdToChat < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :webhook_external_id, :string
    add_index :chats, :webhook_external_id, unique: true
  end
end
