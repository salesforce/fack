class AddPromptToMessage < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :prompt, :text
  end
end
