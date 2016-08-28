require 'rails_helper'

RSpec.describe Feedback, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
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

