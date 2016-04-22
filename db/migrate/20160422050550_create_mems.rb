class CreateMems < ActiveRecord::Migration[5.0]
  def change
    create_table :mems, id: false do |t|
      t.integer :id, index: true, primary_key: true
      t.references :thing

      t.string :text
      t.string :image
      t.string :author_username
    end
  end
end
