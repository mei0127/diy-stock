class UsersController < ApplicationController
  before_action :require_user_logged_in, only: [:edit, :update, :favorite_recipes, :draft_recipes]
  before_action :correct_user, only: [:edit, :update, :favorite_recipes, :draft_recipes]
  
  def show
    @user = User.find(params[:id])
    @recipes = @user.recipes.published
  end

  def new
    @user = User.new
  end

  def create
     @user = User.new(user_params)

    if @user.save
      flash[:success] = '登録しました'
      redirect_to root_url
    else
      flash.now[:danger] = '内容に誤りがあります'
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @user.authenticate(user_params[:password])
      if @user.update(user_params)
        flash[:success] = 'ユーザー情報が更新されました'
        redirect_to @user
      else
        flash.now[:danger] = '内容に誤りがあります'
        render :edit
      end
    else
      flash.now[:danger] = 'パスワードが間違っています'
      render :edit
    end
  end
  
  def favorite_recipes
    @favorite_recipes = @user.favorite_recipes
  end
  
  def draft_recipes
    @draft_recipes = @user.recipes.draft
  end
  
  private

  def user_params
    params.require(:user).permit(:name, :email, :image, :password)
  end
  
  def correct_user
    @user = User.find(params[:id])
    unless @user == current_user
      redirect_to root_url
    end
  end
  
end
