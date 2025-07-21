class ArtifactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_artifact, only: [:show, :edit, :update, :destroy, :download]

  def index
    @artifacts = @project.artifacts.includes(:uploaded_by).order(created_at: :desc)
    @new_artifact = @project.artifacts.build
  end

  def show
  end

  def new
    @artifact = @project.artifacts.build
  end

  def create
    @artifact = @project.artifacts.build(artifact_params)
    @artifact.uploaded_by = current_user
    
    # Use filename as name if name is empty
    if @artifact.name.blank? && @artifact.file.attached?
      @artifact.name = @artifact.file.filename.to_s
    end

    if @artifact.save
      redirect_to @project, notice: 'File was successfully uploaded.'
    else
      @artifacts = @project.artifacts.includes(:uploaded_by).order(created_at: :desc)
      render 'projects/show'
    end
  end

  def edit
    redirect_to @project, alert: 'Not authorized.' unless can_edit_artifact?
  end

  def update
    if can_edit_artifact? && @artifact.update(artifact_params)
      redirect_to @project, notice: 'File was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    if can_edit_artifact?
      @artifact.destroy
      redirect_to @project, notice: 'File was successfully deleted.'
    else
      redirect_to @project, alert: 'Not authorized to delete this file.'
    end
  end

  def download
    if @artifact.file.attached?
      redirect_to @artifact.file, allow_other_host: true
    else
      redirect_to @project, alert: 'No file attached to download.'
    end
  end

  private

  def set_project
    @project = current_user.organization.projects.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: 'Project not found.'
  end

  def set_artifact
    @artifact = @project.artifacts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to @project, alert: 'File not found.'
  end

  def artifact_params
    params.require(:artifact).permit(:name, :description, :artifact_type, :file)
  end

  def can_edit_artifact?
    current_user.admin? || @artifact.uploaded_by == current_user
  end
end
