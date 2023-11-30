class AddLibraryToQuestion < ActiveRecord::Migration[7.0]
  def change
    add_reference :questions, :library, null: true, foreign_key: true
  end
end
