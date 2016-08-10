class Profile < ActiveRecord::Base
  attr_accessible :course, :feedback, :item_successes, :tag, :user
end
# == Schema Information
#
# Table name: profiles
#
#  id         :integer         not null, primary key
#  user       :integer
#  course     :integer
#  tag        :text
#  feedback   :text
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

