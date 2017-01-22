class ChangeDataTypeForAnswers < ActiveRecord::Migration
  def self.up
    change_column :questions, :answers, :text
  end

  def self.down
    change_column :questions, :answers, :string
  end
end
