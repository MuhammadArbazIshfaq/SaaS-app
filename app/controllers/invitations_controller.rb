class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin, except: [:accept]
  before_action :set_project, except: [:accept]
  before_action :set_invitation, only: [:show, :edit, :update, :destroy, :resend]

  def index
    @invitations = @project.invitations.includes(:invited_by, :organization)
                           .order(created_at: :desc)
  end

  def show
  end

  def new
    @invitation = @project.invitations.build
  end

  def create
    @invitation = @project.invitations.build(invitation_params)
    @invitation.organization = current_user.organization
    @invitation.invited_by = current_user
    @invitation.token = SecureRandom.urlsafe_base64(32)

    if @invitation.save
      # Auto-create user account for the invitee
      create_user_for_invitation(@invitation)
      
      # Send invitation email (implement based on your email setup)
      # InvitationMailer.invite(@invitation).deliver_now
      redirect_to @project, notice: 'Invitation sent successfully. User account created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @invitation.update(invitation_params)
      redirect_to @project, notice: 'Invitation updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    @invitation.destroy
    redirect_to @project, notice: 'Invitation cancelled.'
  end

  def resend
    @invitation.update!(token: SecureRandom.urlsafe_base64(32))
    # InvitationMailer.invite(@invitation).deliver_now
    redirect_to @project, notice: 'Invitation resent successfully.'
  end

  def accept
    @invitation = Invitation.find_by!(token: params[:token])
    
    if @invitation.accepted_at.present?
      redirect_to root_path, alert: 'This invitation has already been accepted.'
      return
    end

    if user_signed_in?
      # Check if this is an admin forcing acceptance or normal user acceptance
      if current_user.admin? && request.post?
        # Admin forcing acceptance (for testing/debugging)
        @invitation.update!(accepted_at: Time.current)
        redirect_to project_invitations_path(@invitation.project), 
                   notice: 'Invitation marked as accepted.'
      else
        # Normal user acceptance
        accept_invitation_for_current_user
      end
    else
      # Check if user account exists for this invitation
      invited_user = User.find_by(email: @invitation.email)
      
      if invited_user
        # User account exists, redirect to sign in
        session[:invitation_token] = @invitation.token
        redirect_to new_user_session_path, notice: 'Please sign in with your account to accept the invitation.'
      else
        # This shouldn't happen with auto-creation, but handle it gracefully
        session[:invitation_token] = @invitation.token
        redirect_to new_user_session_path, notice: 'Please sign in to accept the invitation.'
      end
    end
  end

  private

  def set_project
    @project = current_user.organization.projects.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: 'Project not found.'
  end

  def set_invitation
    @invitation = @project.invitations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to @project, alert: 'Invitation not found.'
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end

  def ensure_admin
    redirect_to projects_path, alert: 'Only administrators can manage invitations.' unless current_user.admin?
  end

  def accept_invitation_for_current_user
    Rails.logger.info "=== INVITATION ACCEPTANCE DEBUG ==="
    Rails.logger.info "Current user email: #{current_user.email}"
    Rails.logger.info "Invitation email: #{@invitation.email}"
    Rails.logger.info "Emails match: #{current_user.email == @invitation.email}"
    Rails.logger.info "Invitation accepted_at before: #{@invitation.accepted_at}"
    
    if current_user.email == @invitation.email
      @invitation.update!(accepted_at: Time.current)
      Rails.logger.info "Invitation accepted_at after: #{@invitation.accepted_at}"
      
      # Add user to the project organization if not already a member
      unless current_user.organization == @invitation.organization
        current_user.update!(organization: @invitation.organization, role: @invitation.role)
        Rails.logger.info "Updated user organization to: #{current_user.organization.name}"
      end
      redirect_to @invitation.project, notice: 'Invitation accepted! Welcome to the project.'
    else
      redirect_to root_path, alert: 'This invitation is not for your email address.'
    end
  end

  def create_user_for_invitation(invitation)
    # Check if user already exists
    existing_user = User.find_by(email: invitation.email)
    
    if existing_user
      # User exists, just add them to the organization if not already a member
      unless existing_user.organization == invitation.organization
        existing_user.update!(
          organization: invitation.organization,
          role: invitation.role
        )
      end
    else
      # Create new user account
      # Generate a temporary password that user will need to reset
      temp_password = SecureRandom.alphanumeric(12)
      
      user = User.new(
        email: invitation.email,
        password: temp_password,
        password_confirmation: temp_password,
        organization: invitation.organization,
        role: invitation.role,
        first_name: invitation.email.split('@').first.capitalize, # Use email prefix as first name
        last_name: 'User' # Default last name
      )
      
      # Skip email confirmation for invited users - confirm them immediately
      user.skip_confirmation!
      user.save!
      
      # Store the temp password in invitation for email (optional)
      # invitation.update!(temp_password: temp_password) # if you add this field
    end
  end
end
