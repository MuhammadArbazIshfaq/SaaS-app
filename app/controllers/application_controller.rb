class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  
  # Multi-tenancy setup
  before_action :set_current_tenant
  
  helper_method :current_organization
  
  private
  
  def current_organization
    current_user&.organization
  end
  
  def set_current_tenant
    # You can set tenant based on subdomain, current_user, or other logic
    if user_signed_in?
      ActsAsTenant.current_tenant = current_user.organization
    end
  end
end
