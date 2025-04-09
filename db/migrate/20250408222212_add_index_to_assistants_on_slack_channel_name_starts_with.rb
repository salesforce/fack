class AddIndexToAssistantsOnSlackChannelNameStartsWith < ActiveRecord::Migration[7.1]
  def change
    add_index :assistants, :slack_channel_name_starts_with
  end
end