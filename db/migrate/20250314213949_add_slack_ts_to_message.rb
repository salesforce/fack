class AddSlackTsToMessage < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :slack_ts, :string
  end
end
