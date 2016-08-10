class AddTaskDataToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :task_data, :text, :default => ""
  end
end
