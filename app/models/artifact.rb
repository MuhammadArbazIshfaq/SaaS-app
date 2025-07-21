class Artifact < ApplicationRecord
  belongs_to :project
  belongs_to :uploaded_by
end
