class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :project
  belongs_to :invited_by
end
