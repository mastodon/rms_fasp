class MediaFile < ApplicationRecord
  has_many :storage_requests

  validates :file_size,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 }

  validates :sha512, presence: true, uniqueness: true
  validates :content_type, presence: true, inclusion: Mime::LOOKUP.keys
  validates :width, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :height, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
end
