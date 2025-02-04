class AddLibraryToWebhook < ActiveRecord::Migration[7.1]
  def change
    add_reference :webhooks, :library, null: true, foreign_key: true
  end
end
