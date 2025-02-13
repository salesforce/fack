class AddSlackChannelToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :slack_channel_name, :string
  end
end
