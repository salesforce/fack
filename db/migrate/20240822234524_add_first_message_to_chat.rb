class AddFirstMessageToChat < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :first_message, :text
  end
end
