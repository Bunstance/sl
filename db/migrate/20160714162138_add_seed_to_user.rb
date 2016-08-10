class AddSeedToUser < ActiveRecord::Migration
  def change
    add_column :users, :seed, :integer, :default => 0
  end
end
