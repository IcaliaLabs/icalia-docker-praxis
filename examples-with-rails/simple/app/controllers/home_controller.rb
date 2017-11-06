class HomeController < ApplicationController
  def show
    redirect_to posts_path
  end
end
