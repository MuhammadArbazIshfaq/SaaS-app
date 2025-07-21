class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin, except: [:accept]
  before_action :set_project, except: [:accept, :index]
  before_action :set_invitation, only: [:show, :edit, :update, :destroy, :resend]

  def index
    @invitations = current_user.organization.invitations.includes(:project, :invited_by, :organization)
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
      # Send invitation email (implement based on your email setup)
      # InvitationMailer.invite(@invitation).deliver_now
      redirect_to @project, notice: 'Invitation sent successfully.'
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
      accept_invitation_for_current_user
    else
      # Store invitation token in session and redirect to registration
      session[:invitation_token] = @invitation.token
      redirect_to new_user_registration_path, notice: 'Please create an account to accept the invitation.'
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
    if current_user.email == @invitation.email
      @invitation.update!(accepted_at: Time.current)
      # Add user to the project organization if not already a member
      unless current_user.organization == @invitation.organization
        current_user.update!(organization: @invitation.organization, role: @invitation.role)
      end
      redirect_to @invitation.project, notice: 'Invitation accepted! Welcome to the project.'
    else
      redirect_to root_path, alert: 'This invitation is not for your email address.'
    end
  end
end
