# == Schema Information
#
# Table name: questions
#
#  id               :integer         not null, primary key
#  name             :string(255)
#  parameters       :string(255)
#  answers          :string(255)
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  text             :text(255)
#  precision_regime :string(255)     default("s2")
#  tags             :text            default("")
#  safe_text        :text            default("")
#  author           :integer         default(1)
#  options          :string(255)     default("")
#  answers_array    :string(255)     default("")
#

require 'spec_helper'

# describe Question do
#   pending "add some examples to (or delete) #{__FILE__}"
# end
