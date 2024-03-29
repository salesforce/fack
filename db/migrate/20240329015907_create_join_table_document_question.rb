class CreateJoinTableDocumentQuestion < ActiveRecord::Migration[7.0]
  def change
    create_join_table :documents, :questions do |t|
      # t.index [:document_id, :question_id]
      # t.index [:question_id, :document_id]
    end
  end
end
