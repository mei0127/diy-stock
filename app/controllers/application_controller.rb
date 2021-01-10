class ApplicationController < ActionController::Base
  include SessionsHelper
  
  private

  # ログイン要求
  def require_user_logged_in
    unless logged_in?
      redirect_to login_url
    end
  end
  
  # ログイン処理
  def login(email, password)
    @user = User.find_by(email: email)
    if @user && @user.authenticate(password)
      # ログイン成功
      session[:user_id] = @user.id
      return true
    else
      # ログイン失敗
      return false
    end
  end
  
  # レシピ作成者本人であることの確認
  def user_author_match(recipe_id)
    @recipe = Recipe.find(recipe_id)
    @user = @recipe.user
    unless @user == current_user
      redirect_to root_url
    end
  end
  
  # レシピへのアクセス権確認（本人or友だち？）
  def accessable_recipe_check(recipe_id)
    @recipe = Recipe.find(recipe_id)
    unless current_user.accessable_recipes.include?(@recipe)
      redirect_to root_url
    end
  end
  
  # レシピ検索サイドバー表示の準備
  def prepare_search
    session[:sort].clear if session[:sort]
    session[:keyword].clear if session[:keyword]
    @search_keyword = nil
    @search_feature = {}
    @k_submit = "検索"
    @f_submit = "検索"
  end
  
  # 献立Listサイドバー表示の準備
  def prepare_meals
    @meals = current_user.meals
  end
end
