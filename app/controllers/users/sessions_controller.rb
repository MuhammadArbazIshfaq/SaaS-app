class Users::SessionsController < Devise::SessionsController
  def create
    super do |resource|
      # Check if there's a pending invitation for this user
      if session[:invitation_token] && resource.persisted?
        handle_invitation_acceptance_after_signin(resource)
      end
    end
  end

  private

  def handle_invitation_acceptance_after_signin(user)
    invitation = Invitation.find_by(token: session[:invitation_token])
    
    if invitation && !invitation.accepted? && invitation.email == user.email
      # Accept the invitation
      invitation.update!(accepted_at: Time.current)
      
      # Clear the invitation token from session
      session.delete(:invitation_token)
      
      # Set success message and redirect path
      flash[:notice] = "Welcome! You've successfully joined #{invitation.project.name}."
      session[:after_sign_in_path] = project_path(invitation.project)
    end
  end

  def after_sign_in_path_for(resource)
    session.delete(:after_sign_in_path) || super
  end
end
