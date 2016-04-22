class DefaultScore < ActiveRecord::Migration[5.0]
  def change
    change_column :thing_users, :score, :integer, default: 0
  end
end
