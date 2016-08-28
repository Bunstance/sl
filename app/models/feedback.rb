class Feedback < ActiveRecord::Base
    belongs_to :task
    belongs_to :user
    
    attr_accessible :comment, :grade
    validates :grade, inclusion: { :in => 0..3 }, presence:true
    validates :comment, length: { maximum: 250 }

    def self.by(user_id)
    	self.where("user_id ='#{user_id}'")
    end

    def self.last_by(user_id)
    	self.by(user_id).order(:updated_at).last
    end

    def self.date_of_last_by(user_id)
    	user = User.where("id ='#{user_id}'").first
    	return nil unless user
    	last_fb = self.last_by(user_id)
    	last_fb ? last_fb.updated_at : user.created_at
    end

end
# == Schema Information
#
# Table name: feedbacks
#
#  id         :integer         not null, primary key
#  grade      :integer
#  comment    :string(255)
#  task_id    :integer
#  user_id    :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

