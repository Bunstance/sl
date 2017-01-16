class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  # is this visible on github
  
  def array_from_string string
    # takes the string found when params tries to return an array, and reconstruct the array.
    array = string.split(/[^Q1234567890]+/)
    array.delete("")
    array
  end
  
  
end
