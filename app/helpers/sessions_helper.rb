module SessionsHelper

  def sign_in(user)
    if user.confirmed
    session.delete(:recent_answers) unless self.current_user == user
    self.current_user = user
    cookies.permanent[:remember_token] = user.remember_token
    else
    flash[:failure] = 'Registration not yet confirmed. Check your email for instructions.'
    redirect_to signin_path
    end
  end

  def signed_in?
    !current_user.nil?
  end

  # def sign_in(user)
  #   cookies.permanent[:remember_token] = user.remember_token
  #   session.delete[recent_answers] unless self.current_user == user
  #   self.current_user = user
  # end
  def current_user=(user)
    @current_user = user
  end
  
  def current_user
    @current_user ||= User.find_by_remember_token(cookies[:remember_token])
  end

  def current_user?(user)
    user == current_user
  end

  def sign_out
    self.current_user = nil
    cookies.delete(:remember_token)
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end

  def store_location
    session[:return_to] = request.fullpath
  end

end
