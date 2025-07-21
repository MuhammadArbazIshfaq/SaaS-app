class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true
  
  # Ensure subdomain is URL-safe
  validates :subdomain, format: { with: /\A[a-z0-9\-]+\z/i, message: "can only contain letters, numbers, and hyphens" }
end
