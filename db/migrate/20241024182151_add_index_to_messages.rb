class AddIndexToMessages < ActiveRecord::Migration[7.1]
  def change
    add_index :messages, :created_at
  end
end
