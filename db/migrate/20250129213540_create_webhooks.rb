class CreateWebhooks < ActiveRecord::Migration[7.1]
  def change
    create_table :webhooks do |t|
      t.string :secret_key, null: false
      t.references :assistant, null: false, foreign_key: true
      t.integer :type

      t.timestamps
    end

    add_index :webhooks, :secret_key, unique: true
  end
end
