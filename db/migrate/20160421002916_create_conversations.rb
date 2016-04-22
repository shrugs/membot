class CreateConversations < ActiveRecord::Migration[5.0]
  def change
    create_table :conversations do |t|

      t.string :facebook_user_id, index: true
      t.string :email
      t.string :access_token
      t.string :token_type
      t.integer :expires_in
      t.string :refresh_token
      t.string :scope

      t.integer :memrise_id
      t.string :memrise_username

      t.timestamps
    end
  end
end
