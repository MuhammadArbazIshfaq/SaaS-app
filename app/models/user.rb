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
  has_many :uploaded_artifacts, class_name: 'Artifact', foreign_key: 'uploaded_by_id', dependent: :destroy
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'invited_by_id', dependent: :destroy
  has_many :received_invitations, class_name: 'Invitation', foreign_key: 'email', primary_key: 'email', dependent: :destroy
  
  # Project access through organization
  has_many :projects, -> { distinct }, through: :organization
  
  # Add callbacks for safe deletion
  before_destroy :check_organization_ownership
  after_destroy :cleanup_organization_if_needed
  
  # Validations
  validates :role, inclusion: { in: %w[admin member] }, allow_nil: true
  validates :first_name, presence: true, unless: :invited_user?
  validates :last_name, presence: true, unless: :invited_user?
  
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
    return if organization.present? # Skip if organization is already assigned
    return if role == 'member' # Members don't create organizations
    
    # Only create organization for admin users during NEW organization signup
    # Don't create for invited users who already have an organization assigned
    return unless role == 'admin'
    
    # Organization will be created in the controller with user-provided name
  end
  
  def set_default_role
    # Only set default role if no role is assigned and no organization is present
    # This prevents overriding roles for invited users
    self.role ||= 'admin' if organization.blank?
  end

  def invited_user?
    # User is considered invited if they have an organization but it's not their first organization
    # Or if they were created with a role already assigned
    organization.present? && role.present?
  end

  def check_organization_ownership
    return unless organization && admin?
    
    # Check if this is the only admin in the organization
    other_admins = organization.users.where(role: 'admin').where.not(id: id)
    
    if other_admins.empty?
      # If there are other members, promote one to admin
      other_members = organization.users.where(role: 'member').where.not(id: id)
      
      if other_members.any?
        # Promote the first member to admin
        new_admin = other_members.first
        new_admin.update!(role: 'admin')
        Rails.logger.info "Promoted user #{new_admin.email} to admin for organization #{organization.name}"
      else
        # No other users, organization will be deleted
        Rails.logger.info "Organization #{organization.name} will be deleted as user #{email} is the only member"
      end
    end
  end

  def cleanup_organization_if_needed
    return unless organization
    
    # Check if organization has any remaining users
    if organization.users.count == 0
      # Cancel Stripe subscription if exists
      if organization.stripe_subscription_id.present?
        begin
          Stripe::Subscription.cancel(organization.stripe_subscription_id)
          Rails.logger.info "Cancelled Stripe subscription #{organization.stripe_subscription_id}"
        rescue => e
          Rails.logger.error "Failed to cancel Stripe subscription: #{e.message}"
        end
      end
      
      # Delete the organization
      organization.destroy
      Rails.logger.info "Deleted orphaned organization #{organization.name}"
    end
  rescue => e
    Rails.logger.error "Error during organization cleanup: #{e.message}"
  end
end
