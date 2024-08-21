class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.text :content
      t.integer :from

      t.timestamps
    end
  end
end
