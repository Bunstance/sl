class Group < ActiveRecord::Base
  attr_accessible :scores, :tasks, :teacher, :name
  
  validates :name, presence: true, length: { maximum: 10 },
  		uniqueness:  { case_sensitive: false }

  def members
      User.find_by_group(self.name)
  end
  
  def task_list
    tasks = self.tasks || ''
    tasks.split(' ').map{|x| Task.find(x)}
  end

  def task_names
    self.task_list.map{|x| x.name}
  end

end
# == Schema Information
#
# Table name: groups
#
#  id         :integer         not null, primary key
#  teacher    :integer
#  tasks      :text
#  scores     :text
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  name       :string(255)
#

