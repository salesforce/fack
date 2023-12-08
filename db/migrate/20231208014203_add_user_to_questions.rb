class AddUserToQuestions < ActiveRecord::Migration[7.0]
  def change
    add_reference :questions, :user, null: true, foreign_key: true
  end
end
