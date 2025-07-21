class Project < ApplicationRecord
  belongs_to :organization
  belongs_to :created_by
end
