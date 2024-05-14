class CreateLibraryUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :library_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :library, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :library_users, [:user_id, :library_id], unique: true
  end
end
