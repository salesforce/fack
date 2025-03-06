class CreateGithubAuthorizations < ActiveRecord::Migration[7.1]
  def change
    create_table :github_authorizations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token

      t.timestamps
    end
  end
end
