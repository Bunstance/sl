class Task < ActiveRecord::Base
    include ApplicationHelper
    
    attr_accessible :content, :name, :tags

	validates :name, presence: true, length: { maximum: 50 },
			uniqueness:  { case_sensitive: false }
			
   
    def self.search(search,onlyme,user)
    
        if search&&onlyme
            where('tags LIKE ? AND author = ?', "%#{search}%", user)
        elsif search
            where('tags LIKE ?', "%#{search}%")
        elsif onlyme
            where('id = ?', user)
        else
            where(nil)
        end
    end
    
    def question_count
        self.content.split(' ').count {|x| x[0] == 'Q'}
    end
        
    
end
# == Schema Information
#
# Table name: tasks
#
#  id         :integer         not null, primary key
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  name       :text            default("")
#  tags       :text            default("")
#  content    :text            default("[]")
#

