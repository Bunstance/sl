class AddColumnsToTasks < ActiveRecord::Migration
  def change
  	add_column :tasks, :name, :text, :default => ""
  	add_column :tasks, :tags, :text, :default => ""
  	add_column :tasks, :content, :text, :default => "[]"
  end
end
