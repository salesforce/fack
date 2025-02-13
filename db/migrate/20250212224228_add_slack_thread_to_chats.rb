class AddSlackThreadToChats < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :slack_thread, :string
  end
end
