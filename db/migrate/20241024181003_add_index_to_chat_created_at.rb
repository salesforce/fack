class AddIndexToChatCreatedAt < ActiveRecord::Migration[7.1]
  def change
    add_index :chats, :created_at
  end
end
