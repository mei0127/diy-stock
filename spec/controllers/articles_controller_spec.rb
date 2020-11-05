require 'rails_helper'

RSpec.describe RecipesController, type: :controller do
  describe "#show" do
    context 'リクエストした記事のstatusが「公開」の場合' do
      before do
        @recipe = create(:recipe, status: "published")
        get :show, params: {id: @recipe.id}
      end
      it "200レスポンスが返る" do
        expect(response.status).to eq(200)
      end
      it "@recipeにリクエストされた記事を割り当てる" do
        expect(assigns(:recipe)).to eq(@recipe)
      end
      it ':showテンプレートを表示する' do
        expect(response).to render_template :show
      end
    end
    context 'リクエストした記事のstatusが「非公開」の場合' do
      before do
        @recipe = create(:recipe, status: "draft")
        session[:user_id] = @recipe.user_id
        get :show, params: {id: @recipe.id}
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it "@recipeにリクエストされた記事を割り当てる" do
        expect(assigns(:recipe)).to eq(@recipe)
      end
      it ':previewにリダイレクトする' do
        expect(response).to redirect_to preview_recipe_path(@recipe)
      end
    end
  end
  
  describe "#new" do
    context "ログイン済み" do
      before do
        @user = create(:user)
        session[:user_id] = @user.id
        get :new
      end
      it "200レスポンスが返る" do
        expect(response.status).to eq(200)
      end
      it "@recipeに新しい記事を割り当てる" do
        expect(assigns(:recipe)).to be_a_new(Recipe)
      end
      it ':newテンプレートを表示する' do
        expect(response).to render_template :new
      end
    end
    context "ログインなし" do
      before do
        session[:user_id] = nil
        get :new
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it '#loginにリダイレクトする' do
        expect(response).to redirect_to login_path
      end
    end
  end
  
  describe 'Post #create' do
    before do
      @user = create(:user)
      session[:user_id] = @user.id
    end
    context '有効なパラメータの場合' do
      before do
        @recipe = attributes_for(:recipe)
      end
      it '302レスポンスが返る' do
        post :create, params:{recipe: @recipe}
        expect(response.status).to eq 302
      end
      it 'データベースにユーザーの新しい記事が登録される' do
        expect{
          post :create, params:{recipe: @recipe}
        }.to change(@user.recipes, :count).by(1)
      end
      it '材料入力画面にリダイレクトする' do
        post :create, params:{recipe: @recipe}
        expect(response).to redirect_to new_recipe_ingredient_path(@user.recipes.last)
      end
    end
    context '無効なパラメータの場合' do
      before do
        @invalid_recipe = attributes_for(:recipe, title: nil)
      end
      it '200レスポンスが返る' do
        post :create, params:{recipe: @invalid_recipe}
        expect(response.status).to eq 200
      end
      it 'データベースに新しい記事が登録されない' do
        expect{
          post :create, params:{recipe: @invalid_recipe}
        }.not_to change(@user.recipes, :count)
      end
      it ':newテンプレートを再表示する' do
        post :create, params:{recipe: @invalid_recipe}
        expect(response).to render_template :new
      end
    end
  end
  
  describe "#edit" do
    context '記事作者とログインユーザーが一致' do
      before do
        @user = create(:user)
        @recipe = create(:recipe, user_id: @user.id)
        session[:user_id] = @user.id
        get :edit, params: {id: @recipe.id}
      end
      it "200レスポンスが返る" do
        expect(response.status).to eq(200)
      end
      it "@recipeにリクエストされた記事を割り当てる" do
        expect(assigns(:recipe)).to eq(@recipe)
      end
      it ':editテンプレートを表示する' do
        expect(response).to render_template :edit
      end
    end
    context '記事作者とログインユーザーが一致していない' do
      before do
        @user, @login_user = create_list(:user, 2)
        @recipe = create(:recipe, user_id: @user.id)
        session[:user_id] = @login_user.id
        get :edit, params: {id: @recipe.id}
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it 'rootにリダイレクトする' do
        expect(response).to redirect_to root_path
      end
    end
  end
  
  describe 'Patch #update' do
    context '記事作者とログインユーザーが一致' do
      before do
        @user = create(:user)
        @recipe = create(:recipe, user_id: @user.id)
        @original_title = @recipe.title
        session[:user_id] = @user.id
      end
      context '有効なパラメータの場合' do
        before do
          patch :update, params:{id: @recipe.id, recipe: attributes_for(:recipe, title: "new_title")}
        end
        it '302レスポンスが返る' do
          expect(response.status).to eq 302
        end
        it 'データベースの記事が更新される' do
          @recipe.reload
          expect(@recipe.title).to eq 'new_title'
        end
        it '材料編集画面にリダイレクトする' do
          expect(response).to redirect_to edit_recipe_ingredients_path(@recipe)
        end
      end
      context '無効なパラメータの場合' do
        before do
          patch :update, params:{id: @recipe.id, recipe: attributes_for(:recipe, title: nil)}
        end
        it '200レスポンスが返る' do
          expect(response.status).to eq 200
        end
        it 'データベースのユーザーは更新されない' do
          @recipe.reload
          expect(@recipe.title).to eq @original_title
        end
        it ':editテンプレートを再表示する' do
          expect(response).to render_template :edit
        end
      end
    end
    context '記事作者とログインユーザーが一致しない' do
      before do
        @user, @login_user = create_list(:user, 2)
        @recipe = create(:recipe, user_id: @user.id)
        session[:user_id] = @login_user.id
        patch :update, params:{id: @recipe.id, recipe: attributes_for(:recipe, title: "new_title")}
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it 'rootにリダイレクトする' do
        expect(response).to redirect_to root_path
      end
    end
  end
  
  describe "Delete #destroy" do
    context '記事作者とログインユーザーが一致' do
      before do
        @user = create(:user)
        @recipe = create(:recipe, user_id: @user.id)
        session[:user_id] = @user.id
      end
      it '302レスポンスが返る' do
        delete :destroy, params: {id: @recipe.id}
        expect(response.status).to eq 302
      end
      it 'データベースからユーザーの記事が削除される' do
        expect{
          delete :destroy, params: {id: @recipe.id}
        }.to change(@user.recipes, :count).by(-1)
      end
      it 'rootにリダイレクトする' do
        delete :destroy, params: {id: @recipe.id}
        expect(response).to redirect_to root_path
      end
    end
    context '記事作者とログインユーザーが一致しない' do
      before do
        @user, @login_user = create_list(:user, 2)
        @recipe = create(:recipe, user_id: @user.id)
        session[:user_id] = @login_user.id
      end
      it "302レスポンスが返る" do
        delete :destroy, params: {id: @recipe.id}
        expect(response.status).to eq(302)
      end
      it 'データベースからユーザーの記事は削除されない' do
        expect{
          delete :destroy, params: {id: @recipe.id}
        }.not_to change(@user.recipes, :count)
      end
      it 'rootにリダイレクトする' do
        delete :destroy, params: {id: @recipe.id}
        expect(response).to redirect_to root_path
      end
    end
  end
  
  describe "#preview" do
    context '記事作者とログインユーザーが一致' do
      before do
        @user = create(:user)
        @recipe = create(:recipe, user_id: @user.id)
        session[:user_id] = @user.id
        get :preview, params: {id: @recipe.id}
      end
      it "200レスポンスが返る" do
        expect(response.status).to eq(200)
      end
      it "@recipeにリクエストされた記事を割り当てる" do
        expect(assigns(:recipe)).to eq(@recipe)
      end
      it ':previewテンプレートを表示する' do
        expect(response).to render_template :preview
      end
    end
    context '記事作者とログインユーザーが一致していない' do
      before do
        @user, @login_user = create_list(:user, 2)
        @recipe = create(:recipe, user_id: @user.id)
        session[:user_id] = @login_user.id
        get :preview, params: {id: @recipe.id}
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it 'rootにリダイレクトする' do
        expect(response).to redirect_to root_path
      end
    end
  end
  
  describe 'Patch #publish' do
    context '記事作者とログインユーザーが一致' do
      before do
        @user = create(:user)
        @recipe = create(:recipe, user_id: @user.id, status: "draft")
        session[:user_id] = @user.id
        patch :publish, params:{id: @recipe.id, recipe: attributes_for(:recipe, status: "published")}
      end
      it '302レスポンスが返る' do
        expect(response.status).to eq 302
      end
      it 'データベースの記事が更新される' do
        @recipe.reload
        expect(@recipe.status).to eq 'published'
      end
      it '記事詳細画面にリダイレクトする' do
        expect(response).to redirect_to recipe_url(@recipe)
      end
    end
    context '記事作者とログインユーザーが一致しない' do
      before do
        @user, @login_user = create_list(:user, 2)
        @recipe = create(:recipe, user_id: @user.id, status: "draft")
        session[:user_id] = @login_user.id
        patch :publish, params:{id: @recipe.id, recipe: attributes_for(:recipe, status: "published")}
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it 'データベースの記事は更新されない' do
        @recipe.reload
        expect(@recipe.status).to eq "draft"
      end
      it 'rootにリダイレクトする' do
        expect(response).to redirect_to root_path
      end
    end
  end
  
  describe 'Patch #stop_publish' do
    context '記事作者とログインユーザーが一致' do
      before do
        @user = create(:user)
        @recipe = create(:recipe, user_id: @user.id, status: "published")
        session[:user_id] = @user.id
        patch :stop_publish, params:{id: @recipe.id, recipe: attributes_for(:recipe, status: "draft")}
      end
      it '302レスポンスが返る' do
        expect(response.status).to eq 302
      end
      it 'データベースの記事が更新される' do
        @recipe.reload
        expect(@recipe.status).to eq 'draft'
      end
      it '下書き一覧にリダイレクトする' do
        expect(response).to redirect_to draft_recipes_user_url(@user)
      end
    end
    context '記事作者とログインユーザーが一致しない' do
      before do
        @user, @login_user = create_list(:user, 2)
        @recipe = create(:recipe, user_id: @user.id, status: "published")
        session[:user_id] = @login_user.id
        patch :stop_publish, params:{id: @recipe.id, recipe: attributes_for(:recipe, status: "draft")}
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it 'データベースの記事は更新されない' do
        @recipe.reload
        expect(@recipe.status).to eq "published"
      end
      it 'rootにリダイレクトする' do
        expect(response).to redirect_to root_path
      end
    end
  end
  
  describe "#search" do
    before do
      @recipe_published = create(:recipe, status: "published", title: "本棚の作成", explanation: "木材を用いて本棚を作る" )
      @recipe_draft = create(:recipe, status: "draft", title: "本棚の作成", explanation: "木材を用いて本棚を作る" )
    end
    context '検索ワードが入力されている場合' do
      context '検索ワードのいずれか一つでも"title" または "explanation"に含まれている場合' do
        before do
          get :search, params: {search: "本棚　木材 猫"}
        end
        it "200レスポンスが返る" do
          expect(response.status).to eq(200)
        end
        it "@recipesに同じ記事が重複して登録されない, 下書き記事は登録されない" do
          expect(assigns(:recipes)).to eq([@recipe_published])
        end
        it ':searchテンプレートを表示する' do
          expect(response).to render_template :search
        end
      end
      context '検索ワードが"title"と"explanation"どちらにも含まれていない場合' do
        before do
          get :search, params: {search: "test example"}
        end
        it "200レスポンスが返る" do
          expect(response.status).to eq(200)
        end
        it "@recipesに記事が割り当てられない" do
          expect(assigns(:recipes)).to eq([])
        end
        it ':searchテンプレートを表示する' do
          expect(response).to render_template :search
        end
      end
    end
    context '検索ワードが入力されていない場合' do
      before do
        get :search, params: {search: ""}
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it 'rootにリダイレクトする' do
        expect(response).to redirect_to root_path
      end
    end
  end
end