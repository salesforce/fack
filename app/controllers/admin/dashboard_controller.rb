class Admin::DashboardController < ApplicationController
  before_action :current_user_is_admin?

  def index
    # admin dashboard view
  end
end
