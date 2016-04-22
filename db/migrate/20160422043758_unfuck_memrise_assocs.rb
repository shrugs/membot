class UnfuckMemriseAssocs < ActiveRecord::Migration[5.0]
  def change
    change_table :things do |t|
      t.references :level
    end
  end
end
