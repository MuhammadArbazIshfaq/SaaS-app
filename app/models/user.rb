class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable

  # Multi-tenancy with ActsAsTenant
  acts_as_tenant(:organization)
  belongs_to :organization, optional: true
  
  # Project management relationships
  has_many :created_projects, class_name: 'Project', foreign_key: 'created_by_id', dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :uploaded_artifacts, class_name: 'Artifact', foreign_key: 'uploaded_by_id', dependent: :destroy
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'invited_by_id', dependent: :destroy
  
  # Validations
  validates :role, inclusion: { in: %w[admin member] }
  validates :first_name, presence: true
  validates :last_name, presence: true
  
  # Scopes
  scope :admins, -> { where(role: 'admin') }
  scope :members, -> { where(role: 'member') }
  
  # Auto-create organization for new admin users
  before_validation :create_organization_if_needed, on: :create
  before_validation :set_default_role, if: :new_record?
  
  def admin?
    role == 'admin'
  end
  
  def member?
    role == 'member'
  end
  
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def can_create_projects?
    return false unless organization
    
    if organization.free_plan?
      # Free plan: can create only 1 project
      created_projects.count < 1
    else
      # Premium plan: unlimited projects
      true
    end
  end
  
  def can_switch_plans?
    admin? && organization.present?
  end
  
  private
  
  def create_organization_if_needed
    return if organization.present? || role == 'member'
    
    # Only create organization for admin users during signup
    return unless role == 'admin'
    
    # Organization will be created in the controller with user-provided name
  end
  
  def set_default_role
    self.role ||= 'admin' # Default to admin for new signups
  end
end
