
ActionMailer::Base.delivery_method = :smtp 
ActionMailer::Base.smtp_settings = {
    :address              => "smtp.zoho.com",
    :port                 =>  465,
    :domain               => 'edex-course-childeroland.c9users.io',
    :user_name            => "stemloops@zoho.com",
    :password             => "B1gbottom",         
    :authentication       => :login,
    :ssl                  => true,
    :tls                  => true,
    :enable_starttls_auto => true    

  }