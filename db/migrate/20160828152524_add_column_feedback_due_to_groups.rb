class AddColumnFeedbackDueToGroups < ActiveRecord::Migration
  def change
  	add_column :groups, :feedback_due, :timestamp, :default => 10.years.ago
  end
end
