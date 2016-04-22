class AddStateToConversation < ActiveRecord::Migration[5.0]
  def change
    add_column :conversations, :state, :string, null: false
  end
end
