class AddNoticeToClasses < ActiveRecord::Migration
  def change
  	add_column :groups, :notice, :text, :default => ''
  end
end
