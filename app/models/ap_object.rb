class ApObject < ApplicationRecord
  has_many :storage_requests

  validates :uri, presence: true, uniqueness: true
end
