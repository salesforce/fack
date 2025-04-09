class AddSlackChannelNameToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :slack_channel_name_starts_with, :string
  end
end
