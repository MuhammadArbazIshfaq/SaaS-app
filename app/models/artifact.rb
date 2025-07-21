class Artifact < ApplicationRecord
  belongs_to :project
  belongs_to :uploaded_by, class_name: 'User'
  
  # Active Storage file attachment
  has_one_attached :file
  
  validates :name, presence: true
  validates :artifact_type, presence: true, inclusion: { 
    in: %w[document image spreadsheet presentation other] 
  }
  validates :file, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(artifact_type: type) }
  
  # Helper methods for file handling
  def file_size_human
    return 'No file' unless file.attached?
    ActiveSupport::NumberHelper.number_to_human_size(file.byte_size)
  end
  
  def file_extension
    return '' unless file.attached?
    File.extname(file.filename.to_s)
  end
  
  def display_name
    name.presence || (file.attached? ? file.filename.to_s : 'Untitled')
  end
  
  def icon_class
    case artifact_type
    when 'document'
      'bi-file-text'
    when 'image'
      'bi-file-image'
    when 'spreadsheet'
      'bi-file-spreadsheet'
    when 'presentation'
      'bi-file-slides'
    else
      'bi-file'
    end
  end
end
