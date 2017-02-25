class ChangeQuestionAnswersDataTypeToText < ActiveRecord::Migration


  def self.up
    change_table :questions do |t|
      t.change :answers, :text
    end
  end

  def self.down
    change_table :questions do |t|
      t.change :answers, :string
    end
  end


end
