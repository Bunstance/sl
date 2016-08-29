
class StaticPagesController < ApplicationController
  def home

  	puts "method home called"
  	if current_user
  		redirect_to current_user
  	else
  		redirect_to signin_path
  	end
  end

  def help
  end

  def about
  end
end
