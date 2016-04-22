class CreateQuestion < ActiveRecord::Migration[5.0]
  def change
    create_table :questions do |t|
      t.references :thing
      t.references :conversation
      t.string :box_template
      t.string :given_answer
      t.integer :update_scheduling
      t.integer :score

      t.timestamps
    end
  end
end
