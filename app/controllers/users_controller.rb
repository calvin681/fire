class UsersController < ApplicationController
  before_filter :show_current_user, :only => [:index, :linked_in]
  
  def index
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def linked_in
    omniauth = request.env["omniauth.auth"]
    user = User.where(:provider => omniauth['provider'], :uid => omniauth['uid']).first
    if user
      user.update_attributes(omniauth['credentials'])
      user.import_linkedin_data
      sign_in_and_redirect(user)
      return
    else
      user = User.new({ :provider => omniauth['provider'], :uid => omniauth['uid'] }.merge!(omniauth['credentials']).merge!(omniauth['user_info']))
      if user.save
        user.import_linkedin_data
        sign_in_and_redirect(user)
        return
      end
    end
    # New user data not valid, try again
    flash[:alert] = t('users.linkedin_failed')
    redirect_to users_path
  end
  
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
  
  def failure
    flash[:alert] = t('users.linkedin_failed')
    redirect_to users_path
  end
  
  def logout
    sign_out_and_redirect(:user)
  end
  
  private
  
  def show_current_user
    redirect_to user_path(current_user) if current_user
  end

end
