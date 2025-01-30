class RenameTypeColumnInWebhooks < ActiveRecord::Migration[6.1]
  def change
    rename_column :webhooks, :type, :hook_type
  end
end
