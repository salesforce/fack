class CreateAssistantUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :assistant_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assistant, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :assistant_users, [:user_id, :assistant_id], unique: true
  end
end
