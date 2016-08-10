class AddNameToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :name, :string
    add_index :groups, :name
  end
end
