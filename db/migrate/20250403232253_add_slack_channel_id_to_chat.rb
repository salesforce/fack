class AddSlackChannelIdToChat < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :slack_channel_id, :string
  end
end
