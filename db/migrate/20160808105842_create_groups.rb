class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.text :members
      t.integer :teacher
      t.text :tasks
      t.text :scores

      t.timestamps
    end
  end
end
