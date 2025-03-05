class CreateGoogleAuthorizations < ActiveRecord::Migration[7.1]
  def change
    create_table :google_authorizations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
