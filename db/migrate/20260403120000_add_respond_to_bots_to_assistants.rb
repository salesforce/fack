class AddRespondToBotsToAssistants < ActiveRecord::Migration[7.0]
  def change
    add_column :assistants, :respond_to_bots, :boolean, default: false, null: false
  end
end
