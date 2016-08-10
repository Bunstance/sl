# == Schema Information
#
# Table name: courses
#
#  id         :integer         not null, primary key
#  name       :text
#  tags       :text
#  content    :text            default("[]")
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  tag        :text            default("")
#  author     :integer         default(1)
#

require 'spec_helper'

# describe Course do
#   pending "add some examples to (or delete) #{__FILE__}"
# end
