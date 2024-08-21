class CreateAssistants < ActiveRecord::Migration[7.1]
  def change
    create_table :assistants do |t|
      t.text :user_prompt
      t.text :llm_prompt
      t.text :libraries

      t.timestamps
    end
  end
end
