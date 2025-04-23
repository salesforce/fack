class AddPagerdutyRecentIncidentsToAssistants < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :pagerduty_recent_incidents, :boolean
  end
end
