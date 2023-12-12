class AddExecutionTimeToQuestion < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :generation_time, :float
  end
end
