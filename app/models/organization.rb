class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :invitations, dependent: :destroy
  belongs_to :plan, optional: true
  
  validates :name, presence: true, uniqueness: true
  validates :subdomain, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[trial active suspended cancelled] }
  
  # Ensure subdomain is URL-safe
  validates :subdomain, format: { with: /\A[a-z0-9\-]+\z/i, message: "can only contain letters, numbers, and hyphens" }
  
  # Default status
  after_initialize :set_defaults, if: :new_record?
  
  scope :active, -> { where(status: 'active') }
  scope :trial, -> { where(status: 'trial') }
  scope :suspended, -> { where(status: 'suspended') }
  
  def admin
    users.admins.first
  end
  
  def members
    users.members
  end
  
  def trial?
    status == 'trial'
  end
  
  def active?
    status == 'active'
  end
  
  def suspended?
    status == 'suspended'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def trial_expired?
    trial? && trial_ends_at && trial_ends_at < Time.current
  end
  
  def days_left_in_trial
    return 0 unless trial? && trial_ends_at
    ((trial_ends_at - Time.current) / 1.day).ceil
  end
  
  def free_plan?
    plan&.name&.downcase&.include?('free') || plan.nil?
  end
  
  def premium_plan?
    !free_plan?
  end
  
  def can_add_project?
    return false if suspended? || cancelled?
    return true unless plan # If no plan, allow unlimited for now
    
    if plan.unlimited_projects?
      true # Unlimited projects
    else
      projects.count < plan.project_limit
    end
  end
  
  def projects_limit
    return Float::INFINITY unless plan
    plan.unlimited_projects? ? Float::INFINITY : plan.project_limit
  end
  
  def upgrade_to_premium!
    premium_plan = Plan.find_by(name: 'Premium')
    if premium_plan
      update!(plan: premium_plan, status: 'active')
    end
  end
  
  private
  
  def set_defaults
    self.status ||= 'trial'
    self.trial_ends_at ||= 14.days.from_now
  end
end
