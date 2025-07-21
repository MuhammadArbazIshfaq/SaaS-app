class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]

  def create
    super do |resource|
      if resource.persisted? && session[:invitation_token]
        handle_invitation_acceptance(resource)
      end
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
end
