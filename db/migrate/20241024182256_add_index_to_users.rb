class AddIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :email
  end
end
