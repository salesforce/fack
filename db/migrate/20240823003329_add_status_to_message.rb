class AddStatusToMessage < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :status, :integer, default: 0
  end
end
