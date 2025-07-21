class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :project
  belongs_to :invited_by, class_name: 'User'
  
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: %w[admin member] }
  validates :token, presence: true, uniqueness: true
  
  scope :pending, -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  
  def accepted?
    accepted_at.present?
  end
  
  def pending?
    accepted_at.nil?
  end
end
