class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.integer :grade
      t.string :comment
      
      t.belongs_to :task, index: true
      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
