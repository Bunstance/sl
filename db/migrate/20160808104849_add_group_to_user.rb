class AddGroupToUser < ActiveRecord::Migration
  def change
    add_column :users, :group, :string
    add_index :users, :group
  end
end
