class CreateMemriseCacheModels < ActiveRecord::Migration[5.0]
  def change

    enable_extension :hstore

    create_table :things, id: false do |t|
      t.integer :id, index: true, primary_key: true
      t.hstore :columns
    end

    create_table :levels, id: false do |t|
      t.integer :id, index: true, primary_key: true
      t.integer :pool_id
      t.string :title
      t.integer :column_a
      t.integer :column_b
      t.integer :index
      t.integer :kind

      t.timestamps
    end

    create_table :thing_users do |t|
      t.references :thing
      t.references :conversation
      t.references :level

      t.integer :score  # keeps track of progress
    end

    change_table :conversations do |t|
      t.references :level
    end
  end
end
