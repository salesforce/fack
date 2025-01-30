class AddHookToChats < ActiveRecord::Migration[7.1]
  def change
    add_reference :chats, :webhook, null: true, foreign_key: true
  end
end
