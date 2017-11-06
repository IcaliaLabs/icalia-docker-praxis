require 'rails_helper'

RSpec.describe HomeController, type: :controller do

  describe "GET #show" do
    it "redirects to the 'posts#index' action" do
      get :show
      expect(response).to redirect_to posts_url
    end
  end

end
