class Project < ApplicationRecord
  belongs_to :organization
  belongs_to :created_by, class_name: 'User'
  has_many :artifacts, dependent: :destroy
  has_many :invitations, dependent: :destroy
  
  validates :name, presence: true
  validates :description, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
end
