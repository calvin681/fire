require 'time_helper'

class UsersController < ApplicationController
  include TimeHelper
  
  before_filter :show_current_user, :only => [:index, :linked_in]
  before_filter :ensure_user, :only => [:show, :update]
  
  def index
  end
  
  def show
    now = Time.now
    @current_date_number = date_to_number(now.year, now.month)
    @episodes = @user.episodes(@current_date_number)
    @end_date_number = @episodes.first.end_date_number(@current_date_number) if @episodes.first.present?
  end
  
  def update
    params[:public] = params[:commit].downcase == "public" if params[:commit].present?
    @user.attributes = params
    save = @user.save
    render :json => { :public => @user.public? }.to_json, :status => (save ? :ok : :unprocessable_entity)
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
      user = User.new({ :provider => omniauth['provider'], :uid => omniauth['uid'], :public => false }.
        merge!(omniauth['credentials']).merge!(omniauth['user_info']))
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
  
  def destroy
    current_user.destroy if current_user
    sign_out_and_redirect(:user)
  end
  
  private
  
  def show_current_user
    redirect_to permanent_user_path(current_user.public_id) if current_user
  end
  
  def ensure_user
    @user = User.find(params[:id]) if params[:id] !~ /\//
    @user = User.where(:public_id => params[:id]).first unless @user
    redirect_to users_path if @user.blank?
  end

end
