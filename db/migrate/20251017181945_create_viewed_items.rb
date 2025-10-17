class CreateViewedItems < ActiveRecord::Migration[7.2]
  def change
    create_table :viewed_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :viewable, polymorphic: true, null: false
      t.datetime :viewed_at

      t.timestamps
    end

    # Add composite index for efficient queries by user
    add_index :viewed_items, %i[user_id viewed_at]

    # Add composite index for efficient queries by viewable
    add_index :viewed_items, %i[viewable_type viewable_id viewed_at]

    # Add unique index to ensure one view record per user-viewable combination
    add_index :viewed_items, %i[user_id viewable_type viewable_id], unique: true, name: 'index_viewed_items_on_user_and_viewable'
  end
end
