class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  def index
  end
  # def destroy
  #   sign_out current_user
  #   redirect_to root_path, notice: 'Successfully logged out.'
  # end
end
