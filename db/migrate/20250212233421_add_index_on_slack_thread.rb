class AddIndexOnSlackThread < ActiveRecord::Migration[7.1]
  def change
    add_index :chats, :slack_thread, name: 'index_chats_on_slack_thread'
  end
end
