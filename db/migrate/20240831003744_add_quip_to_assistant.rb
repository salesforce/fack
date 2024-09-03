class AddQuipToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :quip_url, :string
  end
end
