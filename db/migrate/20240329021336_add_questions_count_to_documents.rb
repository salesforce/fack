class AddQuestionsCountToDocuments < ActiveRecord::Migration[6.0]
  def change
    add_column :documents, :questions_count, :integer, default: 0, null: false

    Document.reset_column_information
    Document.find_each do |document|
      Document.reset_counters(document.id, :questions)
    end
  end
end
