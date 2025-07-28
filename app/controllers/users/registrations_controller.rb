class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  def create
    super do |resource|
      if resource.persisted? && session[:invitation_token]
        handle_invitation_acceptance(resource)
      end
    end
  end

  # Handle account deletion
  def destroy
    begin
      Rails.logger.info "User #{current_user.id} (#{current_user.email}) requesting account deletion"
      
      # Use ActsAsTenant.without_tenant to ensure we can delete across tenants
      ActsAsTenant.without_tenant do
        super
      end
      
      Rails.logger.info "User account deletion completed successfully"
    rescue => e
      Rails.logger.error "Error during user account deletion: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Redirect with error message
      redirect_to edit_user_registration_path, alert: "There was an error deleting your account. Please try again or contact support."
    end
  end

  private

  def handle_invitation_acceptance(user)
    invitation = Invitation.find_by(token: session[:invitation_token])
    
    if invitation && !invitation.accepted? && invitation.email == user.email
      # Accept the invitation
      invitation.update!(accepted_at: Time.current)
      
      # Add user to the invitation's organization
      user.update!(
        organization: invitation.organization,
        role: invitation.role
      )
      
      # Clear the invitation token from session
      session.delete(:invitation_token)
      
      # Set success message
      flash[:notice] = "Welcome! You've successfully joined #{invitation.project.name}."
      
      # Redirect to the project after successful registration
      session[:after_sign_up_path] = project_path(invitation.project)
    end
  end

  def after_sign_up_path_for(resource)
    session.delete(:after_sign_up_path) || super
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
end
