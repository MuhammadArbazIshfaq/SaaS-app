class Users::PasswordsController < Devise::PasswordsController
  def new
    super do |resource|
      # If coming from invitation, show helpful message
      if session[:invitation_token]
        flash.now[:notice] = "Set your password to access your account. An account has been created for you."
      end
    end
  end

  def create
    # Get the email from the form
    email = resource_params[:email]
    
    # Find the user
    user = User.find_by(email: email)
    
    if user && user.organization.present? # This is likely an invited user
      # Send password reset email
      user.send_reset_password_instructions
      
      if successfully_sent?(user)
        respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
      else
        respond_with(user)
      end
    else
      # Use default Devise behavior for other users
      super
    end
  end

  def edit
    super do |resource|
      # If this is coming from an invitation, add helpful context
      if session[:invitation_token]
        invitation = Invitation.find_by(token: session[:invitation_token])
        if invitation
          flash.now[:notice] = "Set your password to join #{invitation.project.name}"
        end
      end
    end
  end

  def update
    super do |resource|
      # If password was successfully updated and there's an invitation token
      if resource.errors.empty? && session[:invitation_token]
        invitation = Invitation.find_by(token: session[:invitation_token])
        
        if invitation && !invitation.accepted? && invitation.email == resource.email
          # Accept the invitation automatically
          invitation.update!(accepted_at: Time.current)
          session.delete(:invitation_token)
          
          # Set redirect path to the project
          session[:after_password_update_path] = project_path(invitation.project)
          flash[:notice] = "Password set successfully! Welcome to #{invitation.project.name}."
        end
      end
    end
  end

  protected

  def after_resetting_password_path_for(resource)
    session.delete(:after_password_update_path) || super
  end
end
