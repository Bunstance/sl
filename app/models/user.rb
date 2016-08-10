# == Schema Information
#
# Table name: users
#
#  id              :integer         not null, primary key
#  name            :string(255)
#  email           :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#  password_digest :string(255)
#  remember_token  :string(255)
#  admin           :boolean         default(FALSE)
#  author          :boolean
#  item_successes  :text            default("[]")
#  login_token     :string(255)
#  token_send_time :datetime
#  confirmed       :boolean         default(FALSE)
#  tag             :text            default("")
#  forename        :string(255)
#  surname         :string(255)
#  seed            :integer         default(0)
#  task_data       :text            default("")
#  group           :string(255)
#

# Table name: users

#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime        not null
#  updated_at :datetime        not null


class User < ActiveRecord::Base
  include ApplicationHelper
  attr_accessible :email, :forename, :surname ,:seed, :password,:password_confirmation, :tag, :task_data, :group, :name
         #ensures only these columns are acc'ble - don't worry, the p'word ones don't persist.
  has_secure_password
  
  before_save { |user| user.email = email.downcase } #always save email in lowercase
  before_save :create_remember_token
  
  validates :forename, presence: true, length: { maximum: 20 }
  validates :surname, presence: true, length: { maximum: 30 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  #VALID_EMAIL_REGEX = /\A[\w+\-.]+@connellsixthformcollege.com/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
			uniqueness:  { case_sensitive: false }
  validates :password, length: { minimum: 6 }
  validates :password_confirmation, presence: true
  
  def reseed
    self.update_attribute(:seed, rand(100000))
    #self.save
  end
    
  def send_password_reset
    self.update_attribute(:login_token, SecureRandom.urlsafe_base64)
    self.update_attribute(:token_send_time, Time.zone.now)    
    UserMailer.password_reset(self).deliver
  end

  def send_registration_confirmation
    self.update_attribute(:login_token, SecureRandom.urlsafe_base64)
    self.update_attribute(:token_send_time, Time.zone.now)    
    UserMailer.registration_confirmation(self).deliver
  end

  def task_scores
    self.task_data.split(punc1).map {|x| x.split(punc2).map(&:to_i)}.map {|z| [z[0], z[1]<0,((z[1]*2 + 1).abs - 1)/2, z[2..-1].count {|t| t<0}]}
  end
  
  def task_scores_hash
    Hash[self.task_scores.collect { |v| [v[0], v[1..-1]] }]
  end
  
  def task_list
    group = Group.find_by_name(self.group)
    group ? group.task_list : []
  end
  
  
      

  private

    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end

end
