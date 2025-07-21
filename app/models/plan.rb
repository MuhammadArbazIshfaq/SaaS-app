class Plan < ApplicationRecord
  has_many :organizations, dependent: :nullify
  
  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :billing_cycle, presence: true, inclusion: { in: %w[monthly yearly] }
  validates :max_users, presence: true, numericality: { greater_than: 0 }
  validates :project_limit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(active: true) }
  scope :monthly, -> { where(billing_cycle: 'monthly') }
  scope :yearly, -> { where(billing_cycle: 'yearly') }
  
  def features_list
    return [] if features.blank?
    features.split("\n").map(&:strip).reject(&:blank?)
  end
  
  def monthly?
    billing_cycle == 'monthly'
  end
  
  def yearly?
    billing_cycle == 'yearly'
  end
  
  def free?
    price.zero?
  end
  
  def unlimited_projects?
    project_limit == 0
  end
  
  def project_limit_text
    unlimited_projects? ? "Unlimited" : "Up to #{project_limit}"
  end
end
