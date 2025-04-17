class CreateAssistantRestApiActions < ActiveRecord::Migration[7.1]
  def change
    create_table :assistant_rest_api_actions do |t|
      t.string :endpoint, null: false
      t.text :authorization_header, null: false
      t.references :assistant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
