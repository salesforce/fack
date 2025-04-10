class AddIndexToSlackChannelId < ActiveRecord::Migration[7.1]
  def change
    add_index :chats, :slack_channel_id
  end
end
