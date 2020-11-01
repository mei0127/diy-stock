require 'rails_helper'

RSpec.describe MaterialsController, type: :controller do
  describe "#new" do
    context '記事作者とログインユーザーが一致' do
      before do
        @user = create(:user)
        session[:user_id] = @user.id
        @article = create(:article, user_id: @user.id)
        get :new, params: {article_id: @article.id}
      end
      it "200レスポンスが返る" do
        expect(response.status).to eq(200)
      end
      it "@materialsに材料を割り当てる" do
        expect(assigns(:materials)).to all(be_a_new(Material))
      end
      it "@materialsのarticle_idには@articleのidが登録される" do
        expect(assigns(:materials)).to all(have_attributes(:article_id => @article.id))
      end
      it "@materialsの要素数は10" do
        expect(assigns(:materials).size).to eq 10
      end
      it ':newテンプレートを表示する' do
        expect(response).to render_template :new
      end
    end
    context "記事作者とログインユーザーが一致しない" do
      before do
        @user, @login_user = create_list(:user, 2)
        @article = create(:article, user_id: @user.id)
        session[:user_id] = @login_user.id
        get :new, params: {article_id: @article.id}
      end
      it "302レスポンスが返る" do
        expect(response.status).to eq(302)
      end
      it 'rootにリダイレクトする' do
        expect(response).to redirect_to root_path
      end
    end
  end
  
  describe 'Post #create' do
    before do
      @materials = attributes_for_list(:material, 2)
    end
    context '記事作者とログインユーザーが一致' do
      before do
        @user = create(:user)
        @article = create(:article, user_id: @user.id)
        session[:user_id] = @user.id
      end
      context '有効なパラメータの場合' do
        before do
          @materials += attributes_for_list(:material, 8, name: nil, quantity: nil)
        end
        it '302レスポンスが返る' do
          post :create, params:{materials: @materials, article_id: @article.id}
          expect(response.status).to eq 302
        end
        it "@materialsのarticle_idに@articleのidを割り当てる" do
          post :create, params:{materials: @materials, article_id: @article.id}
          expect(assigns(:materials)).to all(have_attributes(:article_id => @article.id))
        end
        it '有効なパラメータを持つmaterialのみ、データベースに登録される' do
          expect{
            post :create, params:{materials: @materials, article_id: @article.id}
          }.to change(@article.materials, :count).by(2)
        end
        it '材料入力画面にリダイレクトする' do
          post :create, params:{materials: @materials, article_id: @article.id}
          expect(response).to redirect_to new_article_step_path(@user.articles.last)
        end
      end
      context '１つでも無効なパラメータを含む場合' do
        before do
          @materials << attributes_for(:material, name: nil)
        end
        it '200レスポンスが返る' do
          post :create, params:{materials: @materials, article_id: @article.id}
          expect(response.status).to eq 200
        end
        it 'データベースに新しい記事が登録されない' do
          expect{
            post :create, params:{materials: @materials, article_id: @article.id}
          }.not_to change(@article.materials, :count)
        end
        it ':newテンプレートを再表示する' do
          post :create, params:{materials: @materials, article_id: @article.id}
          expect(response).to render_template :new
        end
      end
    end
    context "記事作者とログインユーザーが一致しない" do
      before do
        @user, @login_user = create_list(:user, 2)
        @article = create(:article, user_id: @user.id)
        session[:user_id] = @login_user.id
        post :create, params:{materials: @materials, article_id: @article.id}
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