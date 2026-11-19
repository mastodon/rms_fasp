class MediaFile < ApplicationRecord
  REJECTION_RESPONSE_MAP = {
    RE001: "The ActivityPub object is not public",
    RE002: "The media URL doesn't belong to the ActivityPub object",
    RE003: "The ActivityPub object can't be reached",
    RE004: "Content type not supported",
    RE900: "Other reason, defined by the provider in the message"
  }

  has_many :storage_requests

  validates :file_size,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 }

  validates :sha512, presence: true, uniqueness: true
  validates :content_type, presence: true, inclusion: Mime::LOOKUP.keys
  validates :width, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :height, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
end
