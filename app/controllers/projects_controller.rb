class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy]
  before_action :check_project_creation_limit, only: [:new, :create]

  def index
    @projects = current_user.organization.projects.includes(:created_by, :artifacts)
    @can_create_project = current_user.organization.can_add_project?
  end

  def show
    @artifacts = @project.artifacts.includes(:uploaded_by).order(created_at: :desc)
    @new_artifact = @project.artifacts.build
    @project_members = @project.organization.users.includes(:organization)
  end

  def new
    @project = current_user.organization.projects.build
  end

  def create
    @project = current_user.organization.projects.build(project_params)
    @project.created_by = current_user

    if @project.save
      redirect_to @project, notice: 'Project was successfully created.'
    else
      render :new
    end
  end

  def edit
    # Only admin or project creator can edit
    redirect_to projects_path, alert: 'Not authorized to edit this project.' unless can_edit_project?
  end

  def update
    if can_edit_project? && @project.update(project_params)
      redirect_to @project, notice: 'Project was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    if can_edit_project?
      @project.destroy
      redirect_to projects_path, notice: 'Project was successfully deleted.'
    else
      redirect_to projects_path, alert: 'Not authorized to delete this project.'
    end
  end

  private

  def set_project
    @project = current_user.organization.projects.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: 'Project not found.'
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end

  def check_project_creation_limit
    unless current_user.organization.can_add_project?
      limit = current_user.organization.projects_limit
      redirect_to projects_path, 
                  alert: "You've reached your project limit (#{limit}). Upgrade to Premium for unlimited projects."
    end
  end

  def can_edit_project?
    current_user.admin? || @project.created_by == current_user
  end
end
